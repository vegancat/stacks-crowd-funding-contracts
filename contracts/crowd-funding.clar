;; crowd-funding
;; this contract manages campaigns

;; constants
(define-constant contract-owner tx-sender)
(define-constant create-campaign-fee u2000000)

(define-constant campaign-id-should-be-a-positive-integer (err u100))
(define-constant campaign-id-already-used (err u101))

;; data maps and vars
(define-map campaigns { id: uint } { approved: bool, balance: uint, owner: principal, name: (string-ascii 50), description: (string-ascii 256), logo: (string-ascii 256)})

;; private functions

;; public functions
(define-read-only (is-id-available (id uint)) 
  (begin
    (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
    (ok (is-none (map-get? campaigns {id: id})))
  )
)

(define-public (create-campaign (id uint) (name (string-ascii 50)) (description (string-ascii 256)) (logo (string-ascii 256))) 
  (begin
    (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
    (asserts! (is-eq (is-id-available id) (ok true)) campaign-id-already-used)
    (try! (stx-transfer? create-campaign-fee tx-sender (as-contract tx-sender)))
    ;; #[allow(unchecked_data)]
    (map-set campaigns {id: id} {name: name, balance: u0, description: description, logo: logo, approved: false, owner: tx-sender})
    (ok id)
  )
)
