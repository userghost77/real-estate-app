; -------------------------------------------------------
; Property Validation Agent – MeTTa rules
; -------------------------------------------------------

; === Main Verdict ===
; All critical checks pass → APPROVED
(= (validate-property $prop-id "APPROVED" "All validations passed")
   (And (check-kyc $prop-id)
        (check-documents $prop-id)
        (check-zoning $prop-id)
        (check-area $prop-id)
        (check-ownership $prop-id)
        (not-duplicate-property $prop-id)))

; KYC ok but documents missing → PENDING
(= (validate-property $prop-id "PENDING" "Missing required property documents")
   (And (check-kyc $prop-id)
        (Not (check-documents $prop-id))))

; Documents ok but KYC still pending
(= (validate-property $prop-id "PENDING" "Seller KYC not yet verified")
   (== (kyc-status $prop-id) "pending"))

; Fail on explicit KYC rejection
(= (validate-property $prop-id "REJECTED" "Seller KYC not approved")
   (Not (check-kyc $prop-id)))

; Fail if zoning mismatch
(= (validate-property $prop-id "REJECTED" "Zoning mismatch")
   (Not (check-zoning $prop-id)))

; Fail if property size too small
(= (validate-property $prop-id "REJECTED" "Property area below minimum threshold")
   (Not (check-area $prop-id)))

; Fail if property appears twice
(= (validate-property $prop-id "REJECTED" "Duplicate property listing detected")
   (Not (not-duplicate-property $prop-id)))

; Fail if ownership mismatch
(= (validate-property $prop-id "REJECTED" "Seller not matching registered owner")
   (Not (check-ownership $prop-id)))

; -------------------------------------------------------
; === Core Validation Subrules ===
; -------------------------------------------------------

; ✅ KYC Validation
(= (check-kyc $prop-id)
   (And (== (kyc-status $prop-id) "VERIFIED")
        (has-document $prop-id "govt_id")
        (has-document $prop-id "proof_of_address")))

; ✅ Property Documents
(= (check-documents $prop-id)
   (And (valid-hash (document-hash $prop-id "title_deed"))
        (valid-hash (document-hash $prop-id "tax_certificate"))
        (valid-hash (document-hash $prop-id "encumbrance_certificate"))))

; ✅ Zoning & Compliance
(= (check-zoning $prop-id)
   (And (jurisdiction-allows
          (property-type $prop-id)
          (geo-jurisdiction $prop-id))))

; ✅ Property Area (example threshold > 200 sqft)
(= (check-area $prop-id)
   (> (area-sqft $prop-id) 200))

; ✅ Fraud / Ownership
(= (check-ownership $prop-id)
   (== (registered-owner $prop-id)
       (kyc-owner-name $prop-id)))

; ✅ Duplicate prevention (property not already listed by geo-coordinates)
(= (not-duplicate-property $prop-id)
   (Not (another-property-with-coords
           (geo-coordinates $prop-id)
           $prop-id)))

; -------------------------------------------------------
; === Utility Predicates ===
; -------------------------------------------------------

; IPFS hash present and non-empty
(= (valid-hash $hash)
   (And (Not (== $hash "")) (Not (== $hash "NULL"))))

; Example stub: is this property type allowed in this jurisdiction?
; (You’d encode your jurisdiction table separately)
(= (jurisdiction-allows $type $jur)
   (lookup-zoning-table $jur $type))

; Example stub: check if another listing exists with same coordinates
(= (another-property-with-coords $coords $self)
   (Exists $other (And (== (geo-coordinates $other) $coords)
                       (Not (== $other $self)))))
