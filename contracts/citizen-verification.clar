;; Citizen Verification Contract
;; Validates public service users and manages citizen identity

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_CITIZEN_NOT_FOUND (err u101))
(define-constant ERR_CITIZEN_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Citizen verification status
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_REJECTED u2)
(define-constant STATUS_SUSPENDED u3)

;; Data structures
(define-map citizens
  { citizen-id: principal }
  {
    status: uint,
    verification-date: uint,
    last-updated: uint,
    verification-level: uint
  }
)

(define-map citizen-metadata
  { citizen-id: principal }
  {
    name: (string-ascii 100),
    contact-hash: (string-ascii 64),
    document-hash: (string-ascii 64)
  }
)

(define-data-var total-citizens uint u0)

;; Public functions
(define-public (register-citizen (name (string-ascii 100)) (contact-hash (string-ascii 64)) (document-hash (string-ascii 64)))
  (let ((citizen-id tx-sender))
    (asserts! (is-none (map-get? citizens { citizen-id: citizen-id })) ERR_CITIZEN_ALREADY_EXISTS)
    (map-set citizens
      { citizen-id: citizen-id }
      {
        status: STATUS_PENDING,
        verification-date: block-height,
        last-updated: block-height,
        verification-level: u1
      }
    )
    (map-set citizen-metadata
      { citizen-id: citizen-id }
      {
        name: name,
        contact-hash: contact-hash,
        document-hash: document-hash
      }
    )
    (var-set total-citizens (+ (var-get total-citizens) u1))
    (ok citizen-id)
  )
)

(define-public (verify-citizen (citizen-id principal) (verification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? citizens { citizen-id: citizen-id })) ERR_CITIZEN_NOT_FOUND)
    (map-set citizens
      { citizen-id: citizen-id }
      (merge
        (unwrap-panic (map-get? citizens { citizen-id: citizen-id }))
        {
          status: STATUS_VERIFIED,
          last-updated: block-height,
          verification-level: verification-level
        }
      )
    )
    (ok true)
  )
)

(define-public (update-citizen-status (citizen-id principal) (new-status uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? citizens { citizen-id: citizen-id })) ERR_CITIZEN_NOT_FOUND)
    (asserts! (<= new-status STATUS_SUSPENDED) ERR_INVALID_STATUS)
    (map-set citizens
      { citizen-id: citizen-id }
      (merge
        (unwrap-panic (map-get? citizens { citizen-id: citizen-id }))
        {
          status: new-status,
          last-updated: block-height
        }
      )
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-citizen-info (citizen-id principal))
  (map-get? citizens { citizen-id: citizen-id })
)

(define-read-only (get-citizen-metadata (citizen-id principal))
  (map-get? citizen-metadata { citizen-id: citizen-id })
)

(define-read-only (is-citizen-verified (citizen-id principal))
  (match (map-get? citizens { citizen-id: citizen-id })
    citizen-data (is-eq (get status citizen-data) STATUS_VERIFIED)
    false
  )
)

(define-read-only (get-total-citizens)
  (var-get total-citizens)
)
