// internal/repository/postgres/outlet_repository.go
package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nextdms/dms-outlet-service/internal/domain"
)

// OutletRepository handles all outlet DB operations
type OutletRepository struct {
	pool *pgxpool.Pool
}

func NewOutletRepository(ctx context.Context, dbURL string) (*OutletRepository, error) {
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping db: %w", err)
	}
	return &OutletRepository{pool: pool}, nil
}

func (r *OutletRepository) Close() { r.pool.Close() }

// Create inserts new outlet
func (r *OutletRepository) Create(ctx context.Context, req *domain.CreateOutletRequest) (*domain.Outlet, error) {
	code := GenerateCode()
	if req.Code != "" {
		code = req.Code
	}

	sql := `
		INSERT INTO tblOutlets (
			code, name, short_name, owner_dob, phone, zalo_phone,
			identity_card_number, business_type, business_license_no,
			tax_code, address, province_code, district_code, ward_code,
			street_number, street_name, latitude, longitude, photo_url,
			customer_type_code, customer_channel_code, tier, mcp_id,
			distributor_id, territory_id, country_code, approval_status,
			sync_status, local_id, created_by, creation_date, last_update_date
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
			$16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32
		)
		RETURNING id, code, creation_date, last_update_date
	`

	now := time.Now()
	var dob *time.Time
	if req.OwnerDOB != nil {
		if parsed, err := time.Parse("2006-01-02", *req.OwnerDOB); err == nil {
			dob = &parsed
		}
	}

	syncStatus := domain.SyncStatusSynced
	if req.LocalID != nil && *req.LocalID != "" {
		syncStatus = domain.SyncStatusPending
	}

	out := &domain.Outlet{}
	err := r.pool.QueryRow(ctx, sql,
		code, req.Name, req.ShortName, dob, req.Phone, req.ZaloPhone,
		req.IdentityCard, req.BusinessType, req.BusinessLicense,
		req.TaxCode, req.Address, req.ProvinceCode, req.DistrictCode,
		req.WardCode, req.StreetNumber, req.StreetName, req.Latitude,
		req.Longitude, req.PhotoURL, req.CustomerType, req.CustomerChannel,
		req.Tier, req.MCPID, req.DistributorID, req.TerritoryID,
		req.CountryCode, domain.ApprovalStatusPendingApproval, syncStatus,
		req.LocalID, req.CreatedBy, now, now,
	).Scan(&out.ID, &out.Code, &out.CreationDate, &out.LastUpdateDate)

	if err != nil {
		return nil, fmt.Errorf("insert outlet: %w", err)
	}
	out.Name = req.Name
	out.DistributorID = req.DistributorID
	out.TerritoryID = req.TerritoryID


// GetByID retrieves outlet by ID with scoping
func (r *OutletRepository) GetByID(ctx context.Context, id, distributorID, territoryID int64) (*domain.Outlet, error) {
	sql := `
		SELECT id, code, name, short_name, owner_dob, phone, zalo_phone,
			identity_card_number, business_type, business_license_no, tax_code,
			address, province_code, district_code, ward_code, street_number,
			street_name, latitude, longitude, photo_url, customer_type_code,
			customer_channel_code, tier, mcp_id, distributor_id, territory_id,
			country_code, approval_status, approved_by, approval_date,
			rejected_reason, sync_status, local_id, sync_error_log,
			status, created_by, updated_by, creation_date, last_update_date
		FROM tblOutlets
		WHERE id = $1 AND distributor_id = $2 AND territory_id = $3
	`
	out := &domain.Outlet{}
	err := r.pool.QueryRow(ctx, sql, id, distributorID, territoryID).Scan(
		&out.ID, &out.Code, &out.Name, &out.ShortName, &out.OwnerDOB,
		&out.Phone, &out.ZaloPhone, &out.IdentityCard, &out.BusinessType,
		&out.BusinessLicense, &out.TaxCode, &out.Address, &out.ProvinceCode,
		&out.DistrictCode, &out.WardCode, &out.StreetNumber, &out.StreetName,
		&out.Latitude, &out.Longitude, &out.PhotoURL, &out.CustomerType,
		&out.CustomerChannel, &out.Tier, &out.MCPID, &out.DistributorID,
		&out.TerritoryID, &out.CountryCode, &out.ApprovalStatus, &out.ApprovedBy,
		&out.ApprovalDate, &out.RejectedReason, &out.SyncStatus, &out.LocalID,
		&out.SyncErrorLog, &out.Status, &out.CreatedBy, &out.UpdatedBy,
		&out.CreationDate, &out.LastUpdateDate,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return out, nil
}

// List retrieves outlets by scoping
func (r *OutletRepository) List(ctx context.Context, distributorID, territoryID int64, limit, offset int) ([]domain.Outlet, int, error) {
	countSQL := `SELECT COUNT(*) FROM tblOutlets WHERE distributor_id = $1 AND territory_id = $2`
	var total int
	if err := r.pool.QueryRow(ctx, countSQL, distributorID, territoryID).Scan(&total); err != nil {
		return nil, 0, err
	}

	sql := `
		SELECT id, code, name, short_name, owner_dob, phone, zalo_phone,
			identity_card_number, business_type, business_license_no, tax_code,
			address, province_code, district_code, ward_code, street_number,
			street_name, latitude, longitude, photo_url, customer_type_code,
			customer_channel_code, tier, mcp_id, distributor_id, territory_id,
			country_code, approval_status, approved_by, approval_date,
			rejected_reason, sync_status, local_id, sync_error_log,
			status, created_by, updated_by, creation_date, last_update_date
		FROM tblOutlets
		WHERE distributor_id = $1 AND territory_id = $2
		ORDER BY creation_date DESC
		LIMIT $3 OFFSET $4
	`
	rows, err := r.pool.Query(ctx, sql, distributorID, territoryID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var outlets []domain.Outlet
	for rows.Next() {
		var out domain.Outlet
		if err := rows.Scan(
			&out.ID, &out.Code, &out.Name, &out.ShortName, &out.OwnerDOB,
			&out.Phone, &out.ZaloPhone, &out.IdentityCard, &out.BusinessType,
			&out.BusinessLicense, &out.TaxCode, &out.Address, &out.ProvinceCode,
			&out.DistrictCode, &out.WardCode, &out.StreetNumber, &out.StreetName,
			&out.Latitude, &out.Longitude, &out.PhotoURL, &out.CustomerType,
			&out.CustomerChannel, &out.Tier, &out.MCPID, &out.DistributorID,
			&out.TerritoryID, &out.CountryCode, &out.ApprovalStatus, &out.ApprovedBy,
			&out.ApprovalDate, &out.RejectedReason, &out.SyncStatus, &out.LocalID,
			&out.SyncErrorLog, &out.Status, &out.CreatedBy, &out.UpdatedBy,
			&out.CreationDate, &out.LastUpdateDate,
		); err != nil {
			return nil, 0, err

// CheckDuplicate checks for duplicate outlets
func (r *OutletRepository) CheckDuplicate(ctx context.Context, req *domain.DuplicateCheckRequest) ([]domain.DuplicateMatch, error) {
	var matches []domain.DuplicateMatch
	sql := `SELECT id, code, name FROM tblOutlets
		WHERE distributor_id = $1 AND territory_id = $2 AND status = 'ACTIVE'
		AND ((phone = $3 AND $3 IS NOT NULL) OR (zalo_phone = $4 AND $4 IS NOT NULL)
			OR (tax_code = $5 AND $5 IS NOT NULL) OR (identity_card_number = $6 AND $6 IS NOT NULL))`
	rows, err := r.pool.Query(ctx, sql, req.DistributorID, req.TerritoryID, req.Phone, req.ZaloPhone, req.TaxCode, req.IdentityCard)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var m domain.DuplicateMatch
		if err := rows.Scan(&m.OutletID, &m.OutletCode, &m.OutletName); err != nil {
			continue
		}
		if req.Phone != nil {
			m.FieldName = "phone"
			m.MatchType = "EXACT"


// GetPendingSyncOutlets retrieves pending sync outlets
func (r *OutletRepository) GetPendingSyncOutlets(ctx context.Context, distributorID, territoryID int64) ([]domain.Outlet, error) {
	sql := `SELECT id, code, name, short_name, owner_dob, phone, zalo_phone,
		identity_card_number, business_type, business_license_no, tax_code,
		address, province_code, district_code, ward_code, street_number,
		street_name, latitude, longitude, photo_url, customer_type_code,
		customer_channel_code, tier, mcp_id, distributor_id, territory_id,
		country_code, approval_status, approved_by, approval_date,
		rejected_reason, sync_status, local_id, sync_error_log,
		status, created_by, updated_by, creation_date, last_update_date
		FROM fn_get_pending_sync_outlets($1, $2)`
	rows, err := r.pool.Query(ctx, sql, distributorID, territoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var outlets []domain.Outlet
	for rows.Next() {
		var out domain.Outlet
		if err := rows.Scan(
			&out.ID, &out.Code, &out.Name, &out.ShortName, &out.OwnerDOB,
			&out.Phone, &out.ZaloPhone, &out.IdentityCard, &out.BusinessType,
			&out.BusinessLicense, &out.TaxCode, &out.Address, &out.ProvinceCode,
			&out.DistrictCode, &out.WardCode, &out.StreetNumber, &out.StreetName,
			&out.Latitude, &out.Longitude, &out.PhotoURL, &out.CustomerType,
			&out.CustomerChannel, &out.Tier, &out.MCPID, &out.DistributorID,
			&out.TerritoryID, &out.CountryCode, &out.ApprovalStatus, &out.ApprovedBy,
			&out.ApprovalDate, &out.RejectedReason, &out.SyncStatus, &out.LocalID,
			&out.SyncErrorLog, &out.Status, &out.CreatedBy, &out.UpdatedBy,
			&out.CreationDate, &out.LastUpdateDate,
		); err != nil {


// ApproveOutlet approves an outlet
func (r *OutletRepository) ApproveOutlet(ctx context.Context, id, approvedBy, distributorID, territoryID int64) error {
	sql := `UPDATE tblOutlets SET approval_status = $1, approved_by = $2, approval_date = NOW()
		WHERE id = $3 AND distributor_id = $4 AND territory_id = $5`
	_, err := r.pool.Exec(ctx, sql, domain.ApprovalStatusApproved, approvedBy, id, distributorID, territoryID)
	return err
}

// RejectOutlet rejects an outlet
func (r *OutletRepository) RejectOutlet(ctx context.Context, id, rejectedBy int64, reason string, distributorID, territoryID int64) error {
	sql := `UPDATE tblOutlets SET approval_status = $1, approved_by = $2, approval_date = NOW(), rejected_reason = $3
		WHERE id = $4 AND distributor_id = $5 AND territory_id = $6`
	_, err := r.pool.Exec(ctx, sql, domain.ApprovalStatusRejected, rejectedBy, reason, id, distributorID, territoryID)
	return err
}

// GetValueSetValues retrieves value set values by country
func (r *OutletRepository) GetValueSetValues(ctx context.Context, countryCode string) ([]map[string]interface{}, error) {
	sql := `SELECT id, value_set_code, value_set_name, value_code, value_name, display_order
		FROM tblValueSetValue WHERE country_code = $1 ORDER BY value_set_code, display_order`
	rows, err := r.pool.Query(ctx, sql, countryCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var results []map[string]interface{}
	for rows.Next() {
		var id int64
		var vsCode, vsName, vCode, vName string
		var displayOrder *int
		if err := rows.Scan(&id, &vsCode, &vsName, &vCode, &vName, &displayOrder); err != nil {
			continue
		}
		results = append(results, map[string]interface{}{
			"id": id, "value_set_code": vsCode, "value_set_name": vsName,
			"value_code": vCode, "value_name": vName, "display_order": displayOrder,
		})
	}
	return results, nil
}

// GetProvinces retrieves provinces
func (r *OutletRepository) GetProvinces(ctx context.Context, countryCode string) ([]map[string]interface{}, error) {
	sql := `SELECT province_code, province_name FROM tblProvince WHERE country_code = $1 ORDER BY province_name`
	rows, err := r.pool.Query(ctx, sql, countryCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var results []map[string]interface{}
	for rows.Next() {
		var code, name string
		if err := rows.Scan(&code, &name); err != nil {
			continue
		}
		results = append(results, map[string]interface{}{"province_code": code, "province_name": name})
	}
	return results, nil
}

// GetDistricts retrieves districts
func (r *OutletRepository) GetDistricts(ctx context.Context, provinceCode string) ([]map[string]interface{}, error) {
	sql := `SELECT district_code, district_name FROM tblDistrict WHERE province_code = $1 ORDER BY district_name`
	rows, err := r.pool.Query(ctx, sql, provinceCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var results []map[string]interface{}
	for rows.Next() {
		var code, name string
		if err := rows.Scan(&code, &name); err != nil {
			continue
		}
		results = append(results, map[string]interface{}{"district_code": code, "district_name": name})
	}
	return results, nil
}

// GetWards retrieves wards
func (r *OutletRepository) GetWards(ctx context.Context, districtCode string) ([]map[string]interface{}, error) {
	sql := `SELECT ward_code, ward_name FROM tblWard WHERE district_code = $1 ORDER BY ward_name`
	rows, err := r.pool.Query(ctx, sql, districtCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var results []map[string]interface{}
	for rows.Next() {
		var code, name string
		if err := rows.Scan(&code, &name); err != nil {
			continue
		}
		results = append(results, map[string]interface{}{"ward_code": code, "ward_name": name})
	}
	return results, nil
}

// GenerateCode creates a unique outlet code
func GenerateCode() string { return fmt.Sprintf("OL-%s", uuid.New().String()[:8]) }
			return nil, err
		}
		outlets = append(outlets, out)
	}
	return outlets, nil
}
			matches = append(matches, m)
		}
	}
	return matches, nil
}

// UpdateSyncStatus updates sync status for local_id
func (r *OutletRepository) UpdateSyncStatus(ctx context.Context, localID string, status domain.OutletSyncStatus, errorLog *string) error {
	sql := `UPDATE tblOutlets SET sync_status = $1, sync_error_log = $2 WHERE local_id = $3`
	_, err := r.pool.Exec(ctx, sql, status, errorLog, localID)
	return err
}
		}
		outlets = append(outlets, out)
	}
	return outlets, total, nil
}
	out.CountryCode = req.CountryCode
	out.ApprovalStatus = domain.ApprovalStatusPendingApproval
	out.SyncStatus = syncStatus
	out.LocalID = req.LocalID
	out.CreatedBy = req.CreatedBy
	return out, nil
}