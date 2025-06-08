;; Goal Setting Contract
;; Manages client goal setting and tracking

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_GOAL_NOT_FOUND (err u201))
(define-constant ERR_INVALID_GOAL (err u202))
(define-constant ERR_GOAL_EXISTS (err u203))

;; Goal data structure
(define-map goals
  { goal-id: uint }
  {
    client-id: principal,
    coach-id: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    target-date: uint,
    status: (string-ascii 20),
    progress: uint,
    created-at: uint,
    updated-at: uint
  }
)

;; Client goals mapping
(define-map client-goals
  { client-id: principal }
  { goal-ids: (list 50 uint) }
)

(define-data-var next-goal-id uint u1)

;; Create a new goal
(define-public (create-goal
  (coach-id principal)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (target-date uint)
)
  (let ((goal-id (var-get next-goal-id))
        (client-id tx-sender))
    (map-set goals
      { goal-id: goal-id }
      {
        client-id: client-id,
        coach-id: coach-id,
        title: title,
        description: description,
        category: category,
        target-date: target-date,
        status: "active",
        progress: u0,
        created-at: block-height,
        updated-at: block-height
      }
    )
    ;; Add to client's goal list
    (match (map-get? client-goals { client-id: client-id })
      existing-goals (map-set client-goals
        { client-id: client-id }
        { goal-ids: (unwrap! (as-max-len? (append (get goal-ids existing-goals) goal-id) u50) ERR_INVALID_GOAL) }
      )
      (map-set client-goals
        { client-id: client-id }
        { goal-ids: (list goal-id) }
      )
    )
    (var-set next-goal-id (+ goal-id u1))
    (ok goal-id)
  )
)

;; Update goal progress
(define-public (update-goal-progress (goal-id uint) (progress uint))
  (match (map-get? goals { goal-id: goal-id })
    goal-data (begin
      (asserts! (or (is-eq tx-sender (get client-id goal-data))
                    (is-eq tx-sender (get coach-id goal-data))) ERR_UNAUTHORIZED)
      (map-set goals
        { goal-id: goal-id }
        (merge goal-data {
          progress: progress,
          updated-at: block-height,
          status: (if (>= progress u100) "completed" "active")
        })
      )
      (ok true)
    )
    ERR_GOAL_NOT_FOUND
  )
)

;; Get goal details
(define-read-only (get-goal (goal-id uint))
  (map-get? goals { goal-id: goal-id })
)

;; Get client goals
(define-read-only (get-client-goals (client-id principal))
  (map-get? client-goals { client-id: client-id })
)

;; Mark goal as completed
(define-public (complete-goal (goal-id uint))
  (match (map-get? goals { goal-id: goal-id })
    goal-data (begin
      (asserts! (is-eq tx-sender (get client-id goal-data)) ERR_UNAUTHORIZED)
      (map-set goals
        { goal-id: goal-id }
        (merge goal-data {
          status: "completed",
          progress: u100,
          updated-at: block-height
        })
      )
      (ok true)
    )
    ERR_GOAL_NOT_FOUND
  )
)
