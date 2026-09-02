// internal/domain/outlet.go - Domain entities
package domain

import (
	"time"

	"github.com/google/uuid"
)

// OutletApprovalStatus - Approval Workflow
type OutletApprovalStatus string

const (
	ApprovalStatusDraft           OutletApprovalStatus = "DRAFT"
	ApprovalStatusPendingApproval OutletApprovalStatus = "PENDING_APPROVAL"
	ApprovalStatusApproved       OutletApprovalStatus = "APPROVED"
	ApprovalStatusRejected       OutletApprovalStatus = "REJECTED"
)

// OutletSyncStatus - Offline-First Sync
type OutletSyncStatus string

const (
	SyncStatusPending OutletSyncStatus = "PENDING"
	SyncStatusSyncing OutletSyncStatus = "SYNCING"
	SyncStatusSynced  OutletSyncStatus = "SYNCED"
	SyncStatusFailed  OutletSyncStatus = "FAILED"
)

// CountryCode - Multi-Country
type CountryCode string

const (
	CountryVNM CountryCode = "VNM"
	CountryLAO CountryCode = "LAO"
	CountryCAM CountryCode = "CAM"
	CountryMMR CountryCode = "MMR"
)

// Outlet - main entity
type Outlet struct {
	ID              int64                 `json:"id"`
	Code            string                `json:"code"`
	Name            string                `json:"name"`
	ShortName       *string               `json:"short_name,omitempty"`
	OwnerDOB        *time.Time            `json:"owner_dob,omitempty"`
	Phone           *string               `json:"phone,omitempty"`
	ZaloPhone       *string               `json:"zalo_phone,omitempty"`
	IdentityCard    *string               `json:"identity_card_number,omitempty"`
	BusinessType    *string               `json:"business_type,omitempty"`


// OutletSyncLog - server-side sync log
type OutletSyncLog struct {
	ID                 int64      `json:"id"`
	TableName          string     `json:"table_name"`
	LocalID            *string    `json:"local_id"`
	ServerID           *int64     `json:"server_id"`
	Action             string     `json:"action"`
	Payload            []byte     `json:"payload"`
	SyncStatus         string     `json:"sync_status"`
	ErrorMessage       *string    `json:"error_message"`
	RetryCount         int        `json:"retry_count"`
	CreatedBy          int64      `json:"created_by"`
	CreationDate       time.Time  `json:"creation_date"`
	LastSyncAttempt    *time.Time `json:"last_sync_attempt,omitempty"`
	ResolvedAt         *time.Time `json:"resolved_at,omitempty"`
	ResolutionStrategy *string    `json:"resolution_strategy,omitempty"`
}

// DuplicateMatch - duplicate match result
type DuplicateMatch struct {
	OutletID   int64  `json:"outlet_id"`
	OutletCode string `json:"outlet_code"`
	OutletName string `json:"outlet_name"`
	FieldName  string `json:"field_name"`
	MatchType  string `json:"match_type"`
}

// DuplicateCheckRequest - check-duplicate body
type DuplicateCheckRequest struct {
	Phone         *string  `json:"phone"`
	ZaloPhone     *string  `json:"zalo_phone"`
	TaxCode       *string  `json:"tax_code"`
	IdentityCard  *string  `json:"identity_card_number"`
	Latitude      *float64 `json:"latitude"`
	Longitude     *float64 `json:"longitude"`
	RadiusMeters  float64  `json:"radius_meters"`
	DistributorID int64    `json:"distributor_id" binding:"required"`
	TerritoryID   int64    `json:"territory_id" binding:"required"`
}

// CreateOutletRequest - create outlet with enterprise fields
type CreateOutletRequest struct {
	Code            string        `json:"code" binding:"required"`
	Name            string        `json:"name" binding:"required"`
	ShortName       *string       `json:"short_name"`
	OwnerDOB        *string       `json:"owner_dob"`
	Phone           *string       `json:"phone"`
	ZaloPhone       *string       `json:"zalo_phone"`
	IdentityCard    *string       `json:"identity_card_number"`
	BusinessType    *string       `json:"business_type"`
	BusinessLicense *string       `json:"business_license_no"`
	TaxCode         *string       `json:"tax_code"`
	Address         *string       `json:"address"`
	ProvinceCode    *string       `json:"province_code"`
	DistrictCode    *string       `json:"district_code"`
	WardCode        *string       `json:"ward_code"`
	StreetNumber    *string       `json:"street_number"`
	StreetName      *string       `json:"street_name"`
	Latitude        *float64      `json:"latitude"`
	Longitude       *float64      `json:"longitude"`
	PhotoURL        *string       `json:"photo_url"`
	CustomerType    *string       `json:"customer_type_code"`
	CustomerChannel *string       `json:"customer_channel_code"`
	Tier            *string       `json:"tier"`
	MCPID           *int64        `json:"mcp_id"`
	DistributorID   int64         `json:"distributor_id" binding:"required"`
	TerritoryID     int64         `json:"territory_id" binding:"required"`
	CountryCode     CountryCode   `json:"country_code"`
	LocalID         *string       `json:"local_id"`
	CreatedBy       int64         `json:"created_by" binding:"required"`
}

// GenerateUUID helper
func GenerateUUID() string { return uuid.New().String() }
	BusinessLicense *string               `json:"business_license_no,omitempty"`
	TaxCode         *string               `json:"tax_code,omitempty"`
	Address         *string               `json:"address,omitempty"`
	ProvinceCode    *string               `json:"province_code,omitempty"`
	DistrictCode    *string               `json:"district_code,omitempty"`
	WardCode        *string               `json:"ward_code,omitempty"`
	StreetNumber    *string               `json:"street_number,omitempty"`
	StreetName      *string               `json:"street_name,omitempty"`
	Latitude        *float64              `json:"latitude,omitempty"`
	Longitude       *float64              `json:"longitude,omitempty"`
	PhotoURL        *string               `json:"photo_url,omitempty"`
	CustomerType    *string               `json:"customer_type_code,omitempty"`
	CustomerChannel *string               `json:"customer_channel_code,omitempty"`
	Tier            *string               `json:"tier,omitempty"`
	MCPID           *int64                `json:"mcp_id,omitempty"`
	// Enterprise: Scoping
	DistributorID int64 `json:"distributor_id"`
	TerritoryID   int64 `json:"territory_id"`
	// Enterprise: Approval
	ApprovalStatus OutletApprovalStatus `json:"approval_status"`
	ApprovedBy     *int64               `json:"approved_by,omitempty"`
	ApprovalDate   *time.Time           `json:"approval_date,omitempty"`
	RejectedReason *string              `json:"rejected_reason,omitempty"`
	// Enterprise: Sync
	SyncStatus   OutletSyncStatus `json:"sync_status"`
	LocalID      *string          `json:"local_id,omitempty"`
	SyncErrorLog *string          `json:"sync_error_log,omitempty"`
	// Enterprise: Multi-Country
	CountryCode CountryCode `json:"country_code"`
	// Status
	Status *string `json:"status,omitempty"`
	// Audit
	CreatedBy     int64     `json:"created_by"`
	UpdatedBy     *int64    `json:"updated_by,omitempty"`
	CreationDate  time.Time `json:"creation_date"`
	LastUpdateDate time.Time `json:"last_update_date"`
}