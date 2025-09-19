;; delegate-tracking contract
;; A Clarity smart contract for comprehensive delegate tracking and impact verification.
;; This contract enables decentralized monitoring of delegation activities, 
;; credential management, and impact validation.

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-DELEGATE-NOT-FOUND (err u101))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STAKE (err u103))
(define-constant ERR-ALREADY-REGISTERED (err u104))

;; Contract Administrator
(define-data-var contract-admin principal tx-sender)

;; Delegate Registry
(define-map delegates
  { delegate-id: uint }
  {
    principal: principal,
    name: (string-utf8 50),
    area-of-expertise: (string-utf8 100),
    total-impact-score: uint,
    registered-at: uint
  }
)

;; Delegate Credentials
(define-map delegate-credentials
  { delegate-id: uint, credential-id: uint }
  {
    title: (string-utf8 50),
    description: (string-utf8 200),
    score-impact: uint,
    issued-at: uint
  }
)

;; Tracking Counter Variables
(define-data-var next-delegate-id uint u1)
(define-data-var next-credential-id uint u1)
(define-data-var total-delegate-impact uint u0)

;; Private Functions

;; Calculate delegate impact score
(define-private (calculate-delegate-score (credential-score uint))
  (if (> credential-score u0)
      credential-score
      u0)
)

;; Read-only Functions

;; Get delegate information
(define-read-only (get-delegate (delegate-id uint))
  (map-get? delegates { delegate-id: delegate-id })
)

;; Get delegate credential
(define-read-only (get-delegate-credential (delegate-id uint) (credential-id uint))
  (map-get? delegate-credentials { delegate-id: delegate-id, credential-id: credential-id })
)

;; Get total platform delegate impact
(define-read-only (get-total-delegate-impact)
  (var-get total-delegate-impact)
)

;; Public Functions

;; Set new contract admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

;; Register a new delegate
(define-public (register-delegate 
    (name (string-utf8 50)) 
    (area-of-expertise (string-utf8 100)))
  (let (
    (delegate-id (var-get next-delegate-id))
    (now-block-height block-height)
  )
    (map-set delegates 
      { delegate-id: delegate-id }
      {
        principal: tx-sender,
        name: name,
        area-of-expertise: area-of-expertise,
        total-impact-score: u0,
        registered-at: now-block-height
      }
    )
    (var-set next-delegate-id (+ delegate-id u1))
    (ok delegate-id)
  )
)

;; Issue delegate credential
(define-public (issue-delegate-credential
    (delegate-id uint)
    (title (string-utf8 50))
    (description (string-utf8 200))
    (score-impact uint))
  (let (
    (delegate (unwrap! (map-get? delegates { delegate-id: delegate-id }) ERR-DELEGATE-NOT-FOUND))
    (credential-id (var-get next-credential-id))
    (now-block-height block-height)
    (new-total-impact (+ (get total-impact-score delegate) score-impact))
    (total-platform-impact (+ (var-get total-delegate-impact) score-impact))
  )
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Issue credential
    (map-set delegate-credentials
      { delegate-id: delegate-id, credential-id: credential-id }
      {
        title: title,
        description: description,
        score-impact: score-impact,
        issued-at: now-block-height
      }
    )
    
    ;; Update delegate's total impact
    (map-set delegates 
      { delegate-id: delegate-id }
      (merge delegate { total-impact-score: new-total-impact })
    )
    
    ;; Update platform total impact
    (var-set total-delegate-impact total-platform-impact)
    (var-set next-credential-id (+ credential-id u1))
    
    (ok credential-id)
  )
)