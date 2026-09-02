// internal/delivery/http/handler/outlet_handler.go
package handler

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/nextdms/dms-outlet-service/internal/domain"
	"github.com/nextdms/dms-outlet-service/internal/usecase"
)

// OutletHandler HTTP layer
type OutletHandler struct {
	uc *usecase.OutletUseCase
}

func NewOutletHandler(uc *usecase.OutletUseCase) *OutletHandler {
	return &OutletHandler{uc: uc}
}

// CreateOutlet - POST /api/v1/outlets
func (h *OutletHandler) CreateOutlet(c *gin.Context) {
	var req domain.CreateOutletRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	out, err := h.uc.CreateOutlet(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, out)
}

// SyncOutlet - POST /api/v1/outlets/sync (Offline-First)
func (h *OutletHandler) SyncOutlet(c *gin.Context) {
	var req domain.CreateOutletRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.LocalID == nil || *req.LocalID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "local_id is required for sync"})
		return
	}

	out, err := h.uc.SyncOutlet(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":        err.Error(),
			"local_id":     req.LocalID,
			"sync_status":  "FAILED",
			"should_retry": true,
		})
		return
	}


// UpdateSyncStatus - PATCH /api/v1/outlets/sync-status
func (h *OutletHandler) UpdateSyncStatus(c *gin.Context) {
	var req struct {
		LocalID    string                  `json:"local_id" binding:"required"`
		SyncStatus domain.OutletSyncStatus `json:"sync_status" binding:"required"`
		ErrorLog   *string                `json:"error_log"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.uc.UpdateSyncStatus(c.Request.Context(), req.LocalID, req.SyncStatus, req.ErrorLog); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"local_id": req.LocalID, "sync_status": req.SyncStatus})
}

// GetPendingSyncOutlets - GET /api/v1/outlets/pending-sync
func (h *OutletHandler) GetPendingSyncOutlets(c *gin.Context) {
	distID, _ := strconv.ParseInt(c.Query("distributor_id"), 10, 64)
	terrID, _ := strconv.ParseInt(c.Query("territory_id"), 10, 64)
	if distID == 0 || terrID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "distributor_id and territory_id required"})
		return
	}
	outlets, err := h.uc.GetPendingSyncOutlets(c.Request.Context(), distID, terrID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": outlets, "count": len(outlets)})
}

// CheckDuplicate - POST /api/v1/outlets/check-duplicate
func (h *OutletHandler) CheckDuplicate(c *gin.Context) {
	var req domain.DuplicateCheckRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	matches, err := h.uc.CheckDuplicate(c.Request.Context(), &req)
	if err != nil {


// ApproveOutlet - PATCH /api/v1/outlets/:id/approve
func (h *OutletHandler) ApproveOutlet(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	approvedBy, _ := strconv.ParseInt(c.GetHeader("X-User-Id"), 10, 64)
	distID, _ := strconv.ParseInt(c.Query("distributor_id"), 10, 64)
	terrID, _ := strconv.ParseInt(c.Query("territory_id"), 10, 64)

	if err := h.uc.ApproveOutlet(c.Request.Context(), id, approvedBy, distID, terrID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"id": id, "approval_status": "APPROVED", "approved_by": approvedBy})
}

// RejectOutlet - PATCH /api/v1/outlets/:id/reject
func (h *OutletHandler) RejectOutlet(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	rejectedBy, _ := strconv.ParseInt(c.GetHeader("X-User-Id"), 10, 64)
	distID, _ := strconv.ParseInt(c.Query("distributor_id"), 10, 64)
	terrID, _ := strconv.ParseInt(c.Query("territory_id"), 10, 64)

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.uc.RejectOutlet(c.Request.Context(), id, rejectedBy, req.Reason, distID, terrID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"id": id, "approval_status": "REJECTED", "rejected_reason": req.Reason})
}

// GetValueSetValues - GET /api/v1/value-set-values?country_code=VNM
func (h *OutletHandler) GetValueSetValues(c *gin.Context) {
	countryCode := c.DefaultQuery("country_code", "VNM")
	values, err := h.uc.GetValueSetValues(c.Request.Context(), countryCode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": values, "count": len(values), "country_code": countryCode})
}

// GetProvinces - GET /api/v1/provinces?country_code=VNM
func (h *OutletHandler) GetProvinces(c *gin.Context) {
	countryCode := c.DefaultQuery("country_code", "VNM")
	provinces, err := h.uc.GetProvinces(c.Request.Context(), countryCode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": provinces, "country_code": countryCode})
}

// GetDistricts - GET /api/v1/districts?province_code=HN
func (h *OutletHandler) GetDistricts(c *gin.Context) {
	provinceCode := c.Query("province_code")
	if provinceCode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "province_code required"})
		return
	}
	districts, err := h.uc.GetDistricts(c.Request.Context(), provinceCode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": districts})
}

// GetWards - GET /api/v1/wards?district_code=001
func (h *OutletHandler) GetWards(c *gin.Context) {
	districtCode := c.Query("district_code")
	if districtCode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "district_code required"})
		return
	}
	wards, err := h.uc.GetWards(c.Request.Context(), districtCode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": wards})
}

// UploadPhoto - POST /api/v1/outlets/upload-photo
func (h *OutletHandler) UploadPhoto(c *gin.Context) {
	file, header, err := c.Request.FormFile("photo")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "no photo file"})
		return
	}
	defer file.Close()
	photoURL := fmt.Sprintf("https://cdn.dms.local/uploads/%s", header.Filename)
	c.JSON(http.StatusOK, gin.H{"photo_url": photoURL, "size_bytes": header.Size, "file_name": header.Filename})
}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"is_duplicate": len(matches) > 0, "matches": matches})
}

// GetOutlet - GET /api/v1/outlets/:id
func (h *OutletHandler) GetOutlet(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	distID, _ := strconv.ParseInt(c.Query("distributor_id"), 10, 64)
	terrID, _ := strconv.ParseInt(c.Query("territory_id"), 10, 64)
	out, err := h.uc.GetOutlet(c.Request.Context(), id, distID, terrID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if out == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "outlet not found"})
		return
	}
	c.JSON(http.StatusOK, out)
}

// ListOutlets - GET /api/v1/outlets
func (h *OutletHandler) ListOutlets(c *gin.Context) {
	distID, _ := strconv.ParseInt(c.Query("distributor_id"), 10, 64)
	terrID, _ := strconv.ParseInt(c.Query("territory_id"), 10, 64)
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	outlets, total, err := h.uc.ListOutlets(c.Request.Context(), distID, terrID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": outlets, "total": total, "limit": limit, "offset": offset})
}

// UpdateOutlet - PUT /api/v1/outlets/:id (placeholder)
func (h *OutletHandler) UpdateOutlet(c *gin.Context) {
	c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented yet"})
}

// DeleteOutlet - DELETE /api/v1/outlets/:id (placeholder)
func (h *OutletHandler) DeleteOutlet(c *gin.Context) {
	c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented yet"})
}
	c.JSON(http.StatusOK, gin.H{
		"id":           out.ID,
		"code":         out.Code,
		"local_id":     out.LocalID,
		"sync_status":  out.SyncStatus,
		"sync_time":    out.LastUpdateDate,
		"server_state": out,
	})
}