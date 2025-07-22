;; ArtByte NFT Marketplace Smart Contract

;; Define error constants
(define-constant err-not-admin (err u100))
(define-constant err-not-holder (err u101))
(define-constant err-no-offer (err u102))
(define-constant err-bad-price (err u103))
(define-constant err-bad-token (err u104))
(define-constant err-bad-uri (err u105))
(define-constant err-bad-royalty (err u106))
(define-constant err-invalid-principal (err u107))

;; Define NFT asset
(define-non-fungible-token artbyte-nft uint)

;; Persistent variables
(define-data-var admin principal tx-sender)
(define-data-var token-seq uint u1)

;; Token metadata store
(define-map registry
  { id: uint }
  { holder: principal, minter: principal, metadata: (string-ascii 256), fee: uint }
)

;; Active offers
(define-map market
  { id: uint }
  { cost: uint, vendor: principal }
)

;; Private helper: check admin rights
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Private helper: validate principal
(define-private (is-valid-principal (principal-to-check principal))
  (and 
    (not (is-eq principal-to-check 'SP000000000000000000002Q6VF78))
    (not (is-eq principal-to-check tx-sender))
  )
)

;; Transfer admin role
(define-public (update-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (asserts! (is-valid-principal new-admin) err-invalid-principal)
    (ok (var-set admin new-admin))
  )
)

;; View current admin
(define-read-only (view-admin)
  (ok (var-get admin))
)

;; Mint an NFT
(define-public (create-token (meta (string-ascii 256)) (fee uint))
  (let
    (
      (id (var-get token-seq))
    )
    (asserts! (> (len meta) u0) err-bad-uri)
    (asserts! (<= fee u1000) err-bad-royalty)
    (try! (nft-mint? artbyte-nft id tx-sender))
    (map-set registry
      { id: id }
      { holder: tx-sender, minter: tx-sender, metadata: meta, fee: fee }
    )
    (var-set token-seq (+ id u1))
    (ok id)
  )
)

;; Post token for sale
(define-public (open-offer (id uint) (cost uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? artbyte-nft id) err-bad-token))
    )
    (asserts! (> cost u0) err-bad-price)
    (asserts! (is-eq tx-sender owner) err-not-holder)
    (map-set market
      { id: id }
      { cost: cost, vendor: tx-sender }
    )
    (ok true)
  )
)

;; Withdraw listing
(define-public (revoke-offer (id uint))
  (let
    (
      (listing (unwrap! (map-get? market { id: id }) err-no-offer))
    )
    (asserts! (< id (var-get token-seq)) err-bad-token)
    (asserts! (is-eq tx-sender (get vendor listing)) err-not-holder)
    (map-delete market { id: id })
    (ok true)
  )
)

;; Purchase token
(define-public (purchase (id uint))
  (let
    (
      (offer (unwrap! (map-get? market { id: id }) err-no-offer))
      (price (get cost offer))
      (vendor (get vendor offer))
      (meta (unwrap! (map-get? registry { id: id }) err-bad-token))
      (artist (get minter meta))
      (cut (get fee meta))
      (royalty (/ (* price cut) u10000))
      (payout (- price royalty))
    )
    (asserts! (< id (var-get token-seq)) err-bad-token)
    (try! (stx-transfer? royalty tx-sender artist))
    (try! (stx-transfer? payout tx-sender vendor))
    (try! (nft-transfer? artbyte-nft id vendor tx-sender))
    (map-set registry
      { id: id }
      (merge meta { holder: tx-sender })
    )
    (map-delete market { id: id })
    (ok true)
  )
)

;; View token metadata
(define-read-only (token-info (id uint))
  (ok (unwrap! (map-get? registry { id: id }) err-bad-token))
)

;; View active listing
(define-read-only (offer-info (id uint))
  (ok (unwrap! (map-get? market { id: id }) err-no-offer))
)
