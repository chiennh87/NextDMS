package database

import (
	"context"
	"github.com/nextdms/authservice/configs"
	"github.com/nextdms/authservice/internal/domain/entity"
	"github.com/nextdms/authservice/pkg/errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresDB struct {
	pool *pgxpool.Pool
}

func NewPostgresDB(cfg configs.DatabaseConfig) (*PostgresDB, error) {
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		cfg.User, cfg.Password, cfg.Host, cfg.Port, cfg.DBName)

	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to parse pool config: %w", err)
	}

	poolConfig.MaxConns = int32(cfg.MaxConns)
	poolConfig.MinConns = int32(cfg.MinConns)
	poolConfig.MaxConnLifetime = 1 * time.Hour
	poolConfig.MaxConnIdleTime = 30 * time.Minute

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping db: %w", err)
	}

	return &PostgresDB{pool: pool}, nil
}

func (db *PostgresDB) Close() { db.pool.Close() }

type PostgresUserRepository struct {
	db *PostgresDB
}

func NewPostgresUserRepository(db *PostgresDB) *PostgresUserRepository {
	return &PostgresUserRepository{db: db}
}

func (r *PostgresUserRepository) FindByUsername(ctx context.Context, username string) (*entity.User, error) {
	query := `
		SELECT id, username, phone, email, password_hash, full_name, employee_code, 
		       role_id, is_active, failed_logins, locked_until, created_at, updated_at
		FROM users
		WHERE (username = $1 OR phone = $1 OR email = $1) AND is_deleted = false
		LIMIT 1
	`
	var user entity.User
	var lockedUntil *time.Time
	var email *string

	err := r.db.pool.QueryRow(ctx, query, username).Scan(
		&user.ID, &user.Username, &user.Phone, &email, &user.PasswordHash,
		&user.FullName, &user.EmployeeCode, &user.RoleID, &user.IsActive,
		&user.FailedLogins, &lockedUntil, &user.CreatedAt, &user.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, errors.ErrUserNotFound
	}
	if err != nil {
		return nil, errors.Wrap(err, "FindByUsername failed")
	}
	if email != nil {
		user.Email = *email
	}
	if lockedUntil != nil {
		user.LockedUntil = lockedUntil
	}
	return &user, nil
}

func (r *PostgresUserRepository) FindByID(ctx context.Context, id string) (*entity.User, error) {
	query := `
		SELECT id, username, phone, email, password_hash, full_name, employee_code,
		       role_id, is_active, failed_logins, locked_until, created_at, updated_at
		FROM users WHERE id = $1 AND is_deleted = false
	`
	var user entity.User
	var lockedUntil *time.Time
	var email *string

	err := r.db.pool.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Username, &user.Phone, &email, &user.PasswordHash,
		&user.FullName, &user.EmployeeCode, &user.RoleID, &user.IsActive,
		&user.FailedLogins, &lockedUntil, &user.CreatedAt, &user.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, errors.ErrUserNotFound
	}
	if err != nil {
		return nil, errors.Wrap(err, "FindByID failed")
	}
	if email != nil {
		user.Email = *email
	}
	user.LockedUntil = lockedUntil
	return &user, nil
}

func (r *PostgresUserRepository) IncrementFailedLogins(ctx context.Context, userID string) error {
	query := `UPDATE users SET failed_logins = failed_logins + 1, updated_at = NOW() WHERE id = $1`
	_, err := r.db.pool.Exec(ctx, query, userID)
	return err
}

func (r *PostgresUserRepository) ResetFailedLogins(ctx context.Context, userID string) error {
	query := `UPDATE users SET failed_logins = 0, locked_until = NULL, updated_at = NOW() WHERE id = $1`
	_, err := r.db.pool.Exec(ctx, query, userID)
	return err
}

func (r *PostgresUserRepository) LockAccount(ctx context.Context, userID string, lockedUntil interface{}) error {
	query := `UPDATE users SET locked_until = $2, updated_at = NOW() WHERE id = $1`
	_, err := r.db.pool.Exec(ctx, query, userID, lockedUntil)
	return err
}

func (r *PostgresUserRepository) GetUserPermissions(ctx context.Context, userID string) ([]string, error) {
	query := `
		SELECT DISTINCT p.code
		FROM user_permissions up
		JOIN permissions p ON p.id = up.permission_id
		WHERE up.user_id = $1
		UNION
		SELECT p.code
		FROM role_permissions rp
		JOIN permissions p ON p.id = rp.permission_id
		JOIN users u ON u.role_id = rp.role_id
		WHERE u.id = $1
	`
	rows, err := r.db.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var permissions []string
	for rows.Next() {
		var code string
		if err := rows.Scan(&code); err != nil {
			return nil, err
		}
		permissions = append(permissions, code)
	}
	return permissions, nil
}

func (r *PostgresUserRepository) GetUserRoles(ctx context.Context, userID string) ([]string, error) {
	query := `
		SELECT r.name FROM roles r
		JOIN users u ON u.role_id = r.id
		WHERE u.id = $1
	`
	rows, err := r.db.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var roles []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, err
		}
		roles = append(roles, name)
	}
	return roles, nil
}

func (r *PostgresUserRepository) NeedMasterDataSync(ctx context.Context, userID string) (bool, error) {
	query := `SELECT COALESCE(last_master_sync, '1970-01-01') < NOW() - INTERVAL '24 hours' FROM users WHERE id = $1`
	var needSync bool
	err := r.db.pool.QueryRow(ctx, query, userID).Scan(&needSync)
	return needSync, err
}

func (r *PostgresUserRepository) GetLastMasterDataVersion(ctx context.Context, userID string) (string, error) {
	query := `SELECT COALESCE(master_data_version, 'v0') FROM users WHERE id = $1`
	var version string
	err := r.db.pool.QueryRow(ctx, query, userID).Scan(&version)
	return version, err
}

func (r *PostgresUserRepository) FindByEmail(ctx context.Context, email string) (*entity.User, error) {
query := `SELECT id, username, phone, email, password_hash, full_name, employee_code, role_id, is_active, failed_logins, locked_until, created_at, updated_at FROM users WHERE email = $1 AND is_deleted = false LIMIT 1`
var user entity.User
var lockedUntil *time.Time
var emailPtr *string
err := r.db.pool.QueryRow(ctx, query, email).Scan(&user.ID, &user.Username, &user.Phone, &emailPtr, &user.PasswordHash, &user.FullName, &user.EmployeeCode, &user.RoleID, &user.IsActive, &user.FailedLogins, &lockedUntil, &user.CreatedAt, &user.UpdatedAt)
if err == pgx.ErrNoRows { return nil, errors.ErrUserNotFound }
if err != nil { return nil, errors.Wrap(err, "FindByEmail failed") }
if emailPtr != nil { user.Email = *emailPtr }
if lockedUntil != nil { user.LockedUntil = lockedUntil }
return &user, nil
}

func (r *PostgresUserRepository) UpdatePassword(ctx context.Context, userID string, passwordHash string) error {
query := `UPDATE users SET password_hash = $2, failed_logins = 0, locked_until = NULL, updated_at = NOW() WHERE id = $1`
result, err := r.db.pool.Exec(ctx, query, userID, passwordHash)
if err != nil { return errors.Wrap(err, "UpdatePassword failed") }
if result.RowsAffected() == 0 { return errors.ErrUserNotFound }
return nil
}
