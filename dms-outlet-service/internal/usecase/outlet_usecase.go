// internal/usecase/outlet_usecase.go
package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/nextdms/dms-outlet-service/internal/domain"
	"github.com/nextdms/dms-outlet-service/internal/repository/postgres"
)

// OutletUseCase orchestrates outlet business logic
type OutletUseCase struct {
	repo *postgres.OutletRepository
}

func NewOutletUseCase(repo *postgres.OutletRepository) *OutletUseCase {
	return &OutletUseCase{repo: repo}
}

// CreateOutlet creates new outlet with logging
func (u *OutletUseCase) CreateOutlet(ctx context.Context, req *domain.CreateOutletRequest) (*domain.Outlet, error) {
	out, err := u.repo.Create(ctx, req)
	if err != nil {
		return nil, err
	}

	// Log sync event if this is offline-created
	if req.LocalID != nil && *req.LocalID != "" {
		payload, _ := json.Marshal(req)
		_ = u.repo.LogSyncEvent(ctx, &domain.OutletSyncLog{
			TableName:    "tblOutlets",
			LocalID:      req.LocalID,
			ServerID:     &out.ID,
			Action:       "CREATE",
			Payload:      payload,
			SyncStatus:   "SYNCED",
			CreatedBy:    req.CreatedBy,
			CreationDate: time.Now(),
		})
	}
	return out, nil
}

// SyncOutlet handles sync of offline-created outlet
func (u *OutletUseCase) SyncOutlet(ctx context.Context, req *domain.CreateOutletRequest) (*domain.Outlet, error) {
	if req.LocalID == nil || *req.LocalID == "" {
		return nil, fmt.Errorf("local_id is required for sync")
	}
	req.CountryCode = "" // will be set in repo
	out, err := u.repo.Create(ctx, req)
	if err != nil {
		// Log failure
		payload, _ := json.Marshal(req)
		errMsg := err.Error()
		_ = u.repo.LogSyncEvent(ctx, &domain.OutletSyncLog{
			TableName:    "tblOutlets",
			LocalID:      req.LocalID,
			Action:       "CREATE",
			Payload:      payload,
			SyncStatus:   "FAILED",
			ErrorMessage: &errMsg,
			RetryCount:   1,
			CreatedBy:    req.CreatedBy,
			CreationDate: time.Now(),
		})
		return nil, err
	}
	return out, nil
}

// UpdateSyncStatus updates sync status after client confirmed
func (u *OutletUseCase) UpdateSyncStatus(ctx context.Context, localID string, status domain.OutletSyncStatus, errorLog *string) error {
	return u.repo.UpdateSyncStatus(ctx, localID, status, errorLog)
}

// GetPendingSyncOutlets returns pending outlets
func (u *OutletUseCase) GetPendingSyncOutlets(ctx context.Context, distributorID, territoryID int64) ([]domain.Outlet, error) {
	return u.repo.GetPendingSyncOutlets(ctx, distributorID, territoryID)
}

// CheckDuplicate checks for duplicates
func (u *OutletUseCase) CheckDuplicate(ctx context.Context, req *domain.DuplicateCheckRequest) ([]domain.DuplicateMatch, error) {
	return u.repo.CheckDuplicate(ctx, req)
}

// GetOutlet retrieves by ID
func (u *OutletUseCase) GetOutlet(ctx context.Context, id, distributorID, territoryID int64) (*domain.Outlet, error) {
	return u.repo.GetByID(ctx, id, distributorID, territoryID)
}

// ListOutlets returns scoped list
func (u *OutletUseCase) ListOutlets(ctx context.Context, distributorID, territoryID int64, limit, offset int) ([]domain.Outlet, int, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	if offset < 0 {
		offset = 0
	}
	return u.repo.List(ctx, distributorID, territoryID, limit, offset)
}

// ApproveOutlet approves an outlet
func (u *OutletUseCase) ApproveOutlet(ctx context.Context, id, approvedBy, distributorID, territoryID int64) error {
	return u.repo.ApproveOutlet(ctx, id, approvedBy, distributorID, territoryID)
}

// RejectOutlet rejects an outlet
func (u *OutletUseCase) RejectOutlet(ctx context.Context, id, rejectedBy int64, reason string, distributorID, territoryID int64) error {
	return u.repo.RejectOutlet(ctx, id, rejectedBy, reason, distributorID, territoryID)
}

// GetValueSetValues returns value set for country
func (u *OutletUseCase) GetValueSetValues(ctx context.Context, countryCode string) ([]map[string]interface{}, error) {
	return u.repo.GetValueSetValues(ctx, countryCode)
}

// GetProvinces returns provinces
func (u *OutletUseCase) GetProvinces(ctx context.Context, countryCode string) ([]map[string]interface{}, error) {
	return u.repo.GetProvinces(ctx, countryCode)
}

// GetDistricts returns districts
func (u *OutletUseCase) GetDistricts(ctx context.Context, provinceCode string) ([]map[string]interface{}, error) {
	return u.repo.GetDistricts(ctx, provinceCode)
}

// GetWards returns wards
func (u *OutletUseCase) GetWards(ctx context.Context, districtCode string) ([]map[string]interface{}, error) {
	return u.repo.GetWards(ctx, districtCode)
}