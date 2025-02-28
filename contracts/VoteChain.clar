;; VoteChain - Decentralized Blockchain Voting System

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_BALLOT_EXISTS (err u101))
(define-constant ERR_BALLOT_NOT_FOUND (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_INVALID_CHOICE (err u105))
(define-constant ERR_SELF_DELEGATION (err u106))
(define-constant ERR_DELEGATION_CYCLE (err u107))
(define-constant ERR_INVALID_INPUT (err u108))
(define-constant ERR_NOT_ENOUGH_TOKENS (err u109))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u110))

;; Data Variables
(define-data-var governance-controller principal tx-sender)
(define-data-var epoch-counter uint u0)

;; Maps
(define-map Ballots 
  { ballot-id: uint } 
  { 
    title: (string-ascii 50), 
    choices: (list 10 (string-ascii 20)),
    expiration: uint,
    tally: uint
  }
)

(define-map Ballots-Cast 
  { ballot-id: uint, voter: principal } 
  { choice: (string-ascii 20), influence: uint }
)

(define-map VoterInfluence 
  { voter: principal } 
  { influence: uint }
)

(define-map Proxies
  { grantor: principal }
  { proxy: principal }
)

;; Private Functions
(define-private (is-governance-controller)
  (is-eq tx-sender (var-get governance-controller))
)

(define-private (check-ballot-exists (ballot-id uint))
  (is-some (map-get? Ballots { ballot-id: ballot-id }))
)

(define-private (check-voting-open (ballot-id uint))
  (match (map-get? Ballots { ballot-id: ballot-id })
    ballot-data (< (var-get epoch-counter) (get expiration ballot-data))
    false)
)

(define-private (get-voter-influence (voter principal))
  (default-to u1 (get influence (map-get? VoterInfluence { voter: voter })))
)

(define-private (update-tally (ballot-id uint) (influence uint))
  (match (map-get? Ballots { ballot-id: ballot-id })
    ballot-data (map-set Ballots 
                { ballot-id: ballot-id }
                (merge ballot-data { tally: (+ (get tally ballot-data) influence) }))
    false)
)

(define-private (validate-string (input (string-ascii 50)))
  (and (>= (len input) u1) (<= (len input) u50))
)

(define-private (validate-choices (choices (list 10 (string-ascii 20))))
  (and 
    (>= (len choices) u2)
    (<= (len choices) u10)
    (fold and (map validate-string choices) true)
  )
)

(define-private (validate-token-threshold (voter principal))
  (> (get-voter-influence voter) u0)
)

;; Public Functions
(define-public (create-ballot (title (string-ascii 50)) (choices (list 10 (string-ascii 20))) (duration uint))
  (begin
    (asserts! (is-governance-controller) ERR_UNAUTHORIZED)
    (asserts! (validate-string title) ERR_INVALID_INPUT)
    (asserts! (validate-choices choices) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (let 
      (
        (ballot-id (+ u1 (default-to u0 (get tally (map-get? Ballots { ballot-id: u0 })))))
        (current-epoch (var-get epoch-counter))
      )
      (asserts! (not (check-ballot-exists ballot-id)) ERR_BALLOT_EXISTS)
      (ok (map-set Ballots 
            { ballot-id: ballot-id }
            { 
              title: title, 
              choices: choices,
              expiration: (+ current-epoch duration),
              tally: u0
            })))
  )
)

(define-public (submit-vote (ballot-id uint) (choice (string-ascii 20)))
  (let 
    (
      (voter-influence (get-voter-influence tx-sender))
      (ballot (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND))
    )
    (asserts! (check-voting-open ballot-id) ERR_VOTING_ENDED)
    (asserts! (is-some (index-of (get choices ballot) choice)) ERR_INVALID_CHOICE)
    (asserts! (is-none (map-get? Ballots-Cast { ballot-id: ballot-id, voter: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (validate-token-threshold tx-sender) ERR_NOT_ENOUGH_TOKENS)
    (map-set Ballots-Cast 
      { ballot-id: ballot-id, voter: tx-sender }
      { choice: choice, influence: voter-influence })
    (update-tally ballot-id voter-influence)
    (ok true)
  )
)

(define-public (assign-proxy (proxy principal))
  (begin
    (asserts! (not (is-eq tx-sender proxy)) ERR_SELF_DELEGATION)
    (asserts! (is-none (map-get? Proxies { grantor: proxy })) ERR_DELEGATION_CYCLE)
    (map-set Proxies { grantor: tx-sender } { proxy: proxy })
    (map-set VoterInfluence 
      { voter: proxy }
      { influence: (+ (get-voter-influence proxy) (get-voter-influence tx-sender)) })
    (map-delete VoterInfluence { voter: tx-sender })
    (ok true)
  )
)

(define-public (close-ballot (ballot-id uint))
  (begin
    (asserts! (is-governance-controller) ERR_UNAUTHORIZED)
    (asserts! (check-ballot-exists ballot-id) ERR_BALLOT_NOT_FOUND)
    (let ((ballot (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND)))
      (ok (map-set Ballots 
            { ballot-id: ballot-id }
            (merge ballot { expiration: (var-get epoch-counter) })))
    )
  )
)

(define-public (advance-epoch)
  (begin
    (asserts! (is-governance-controller) ERR_UNAUTHORIZED)
    (ok (var-set epoch-counter (+ (var-get epoch-counter) u1)))
  )
)

;; Read-Only Functions
(define-read-only (get-ballot-tally (ballot-id uint))
  (ok (get tally (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND)))
)

(define-read-only (get-voter-influence-level (voter principal))
  (ok (get-voter-influence voter))
)

(define-read-only (get-ballot-status (ballot-id uint))
  (let ((ballot (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND)))
    (ok (< (var-get epoch-counter) (get expiration ballot)))
  )
)

(define-read-only (get-current-epoch)
  (ok (var-get epoch-counter))
)