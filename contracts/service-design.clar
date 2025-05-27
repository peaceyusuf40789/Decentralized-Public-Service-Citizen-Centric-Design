;; Service Design Contract
;; Records citizen-centric service design and configurations

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_SERVICE_NOT_FOUND (err u201))
(define-constant ERR_SERVICE_ALREADY_EXISTS (err u202))
(define-constant ERR_INVALID_PRIORITY (err u203))

;; Service priority levels
(define-constant PRIORITY_LOW u1)
(define-constant PRIORITY_MEDIUM u2)
(define-constant PRIORITY_HIGH u3)
(define-constant PRIORITY_CRITICAL u4)

;; Data structures
(define-map services
  { service-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    priority: uint,
    created-at: uint,
    updated-at: uint,
    is-active: bool,
    citizen-requirements: (list 10 (string-ascii 50))
  }
)

(define-map service-metrics
  { service-id: uint }
  {
    total-users: uint,
    satisfaction-score: uint,
    completion-rate: uint,
    average-time: uint
  }
)

(define-data-var next-service-id uint u1)
(define-data-var total-services uint u0)

;; Public functions
(define-public (create-service
  (name (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (priority uint)
  (requirements (list 10 (string-ascii 50)))
)
  (let ((service-id (var-get next-service-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= priority PRIORITY_CRITICAL) ERR_INVALID_PRIORITY)
    (asserts! (>= priority PRIORITY_LOW) ERR_INVALID_PRIORITY)

    (map-set services
      { service-id: service-id }
      {
        name: name,
        description: description,
        category: category,
        priority: priority,
        created-at: block-height,
        updated-at: block-height,
        is-active: true,
        citizen-requirements: requirements
      }
    )

    (map-set service-metrics
      { service-id: service-id }
      {
        total-users: u0,
        satisfaction-score: u0,
        completion-rate: u0,
        average-time: u0
      }
    )

    (var-set next-service-id (+ service-id u1))
    (var-set total-services (+ (var-get total-services) u1))
    (ok service-id)
  )
)

(define-public (update-service
  (service-id uint)
  (name (string-ascii 100))
  (description (string-ascii 500))
  (priority uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? services { service-id: service-id })) ERR_SERVICE_NOT_FOUND)
    (asserts! (<= priority PRIORITY_CRITICAL) ERR_INVALID_PRIORITY)

    (map-set services
      { service-id: service-id }
      (merge
        (unwrap-panic (map-get? services { service-id: service-id }))
        {
          name: name,
          description: description,
          priority: priority,
          updated-at: block-height
        }
      )
    )
    (ok true)
  )
)

(define-public (toggle-service-status (service-id uint))
  (let ((service-data (unwrap! (map-get? services { service-id: service-id }) ERR_SERVICE_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set services
      { service-id: service-id }
      (merge service-data { is-active: (not (get is-active service-data)) })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-service (service-id uint))
  (map-get? services { service-id: service-id })
)

(define-read-only (get-service-metrics (service-id uint))
  (map-get? service-metrics { service-id: service-id })
)

(define-read-only (get-total-services)
  (var-get total-services)
)

(define-read-only (is-service-active (service-id uint))
  (match (map-get? services { service-id: service-id })
    service-data (get is-active service-data)
    false
  )
)
