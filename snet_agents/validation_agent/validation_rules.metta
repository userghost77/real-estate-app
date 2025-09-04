; -------------------------------------------------------
; Property Validation Agent – MeTTa knowledge/rules
; -------------------------------------------------------

; === Main Validation ===
; If all key checks pass, approve.
(= (validate-property $prop-id "APPROVED")
   (And (check-kyc $prop-id)
        (check-documents $prop-id)
        (check-area $prop-id)
        (check-ownership $prop-id)
        (check-location $prop-id)))

; Needs more info if KYC ok but documents missing
(= (validate-property $prop-id "NEEDS_MORE_INFO" "Missing required documents")
   (And (check-kyc $prop-id)
        (Not (check-documents $prop-id))))

; Needs more info if docs are ok but KYC pending
(= (validate-property $prop-id "NEEDS_MORE_INFO" "KYC pending")
   (== (kyc-status $prop-id) "pending"))

; Catch-all rejection if KYC failed
(= (validate-property $prop-id "REJECTED" "KYC not approved")
   (Not (check-kyc $prop-id)))

; Fallback rejection if area invalid
(= (validate-property $prop-id "REJECTED" "Invalid property area")
   (Not (check-area $prop-id)))

; === Core Sub-Rules ===
; KYC must be explicitly approved
(= (check-kyc $prop-id)
   (== (kyc-status $prop-id) "approved"))

; Must have key legal documents
(= (check-documents $prop-id)
   (And (has-document $prop-id "deed")
        (has-document $prop-id "tax_receipts")))

; Basic area rule (sqft > 500)
(= (check-area $prop-id)
   (> (area-sqft $prop-id) 500))

; Owner identity present & matches KYC entity
(= (check-ownership $prop-id)
   (== (registered-owner $prop-id)
       (kyc-owner-name $prop-id)))

; Location must exist in registry and not blacklisted
(= (check-location $prop-id)
   (And (location-exists $prop-id)
        (Not (blacklisted-location $prop-id))))

