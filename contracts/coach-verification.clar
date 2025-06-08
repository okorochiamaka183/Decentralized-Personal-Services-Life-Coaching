;; Coach Verification Contract
;; Manages the verification and registration of life coaches

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_COACH_EXISTS (err u101))
(define-constant ERR_COACH_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Coach data structure
(define-map coaches
  { coach-id: principal }
  {
    name: (string-ascii 100),
    credentials: (string-ascii 200),
    specialization: (string-ascii 100),
    verified: bool,
    rating: uint,
    total-sessions: uint,
    created-at: uint
  }
)

;; Verification requests
(define-map verification-requests
  { request-id: uint }
  {
    coach-id: principal,
    credentials: (string-ascii 200),
    status: (string-ascii 20),
    submitted-at: uint
  }
)

(define-data-var next-request-id uint u1)

;; Register as a coach
(define-public (register-coach (name (string-ascii 100)) (credentials (string-ascii 200)) (specialization (string-ascii 100)))
  (let ((coach-id tx-sender))
    (asserts! (is-none (map-get? coaches { coach-id: coach-id })) ERR_COACH_EXISTS)
    (map-set coaches
      { coach-id: coach-id }
      {
        name: name,
        credentials: credentials,
        specialization: specialization,
        verified: false,
        rating: u0,
        total-sessions: u0,
        created-at: block-height
      }
    )
    (ok coach-id)
  )
)

;; Submit verification request
(define-public (submit-verification-request (credentials (string-ascii 200)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        coach-id: tx-sender,
        credentials: credentials,
        status: "pending",
        submitted-at: block-height
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Verify coach (admin only)
(define-public (verify-coach (coach-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? coaches { coach-id: coach-id })
      coach-data (begin
        (map-set coaches
          { coach-id: coach-id }
          (merge coach-data { verified: true })
        )
        (ok true)
      )
      ERR_COACH_NOT_FOUND
    )
  )
)

;; Get coach info
(define-read-only (get-coach-info (coach-id principal))
  (map-get? coaches { coach-id: coach-id })
)

;; Check if coach is verified
(define-read-only (is-coach-verified (coach-id principal))
  (match (map-get? coaches { coach-id: coach-id })
    coach-data (get verified coach-data)
    false
  )
)
