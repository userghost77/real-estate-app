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

; === Helper facts (examples / stubs) ===
; You can populate these from your data ingestion layer
; (kyc-status "prop-101") -> "approved"
; (has-document "prop-101" "deed")
; (area-sqft "prop-101") -> 1450
; (registered-owner "prop-101") -> "Ravi Sharma"
; (kyc-owner-name "prop-101") -> "Ravi Sharma"
; (location-exists "prop-101")
; (Not (blacklisted-location "prop-101"))

; -------------------------------------------------------
; Extension points:
;   - add floodzone checks
;   - zoning compliance
;   - encumbrance search
; just append new (= (validate-property …) …) clauses
; -------------------------------------------------------
How it behaves
APPROVED → all sub-rules return true.

NEEDS_MORE_INFO → partial pass (e.g., KYC ok, docs missing).

REJECTED → fails KYC or area or later checks.

Rules are matched top-down: first satisfied clause “fires,” others skipped.

Would you also like me to show an example Atomspace knowledge base (facts for one property) so you can run a quick (validate-property "prop-101" $status $reason) query and see the outcome?







You said:
yes show


ChatGPT said:
Here’s a tiny Atomspace fact base you can drop in the same MeTTa file (or load separately) so you can actually call the rule:

metta
Copy code
; -------------------------------------------------------
; Example facts for one property in Atomspace
; -------------------------------------------------------

; --- Property "prop-101" ---
(kyc-status "prop-101")          "approved"
(has-document "prop-101" "deed")
(has-document "prop-101" "tax_receipts")
(area-sqft "prop-101")           1450
(registered-owner "prop-101")    "Ravi Sharma"
(kyc-owner-name "prop-101")      "Ravi Sharma"
(location-exists "prop-101")     true
(Not (blacklisted-location "prop-101"))

; --- Property "prop-202" (missing tax receipts) ---
(kyc-status "prop-202")          "approved"
(has-document "prop-202" "deed")
(area-sqft "prop-202")           980
(registered-owner "prop-202")    "Asha Patel"
(kyc-owner-name "prop-202")      "Asha Patel"
(location-exists "prop-202")     true
(Not (blacklisted-location "prop-202"))

; --- Property "prop-303" (KYC pending) ---
(kyc-status "prop-303")          "pending"
(has-document "prop-303" "deed")
(has-document "prop-303" "tax_receipts")
(area-sqft "prop-303")           700
(registered-owner "prop-303")    "Imran Khan"
(kyc-owner-name "prop-303")      "Imran Khan"
(location-exists "prop-303")     true
(Not (blacklisted-location "prop-303"))

; -------------------------------------------------------
; Query examples (run in your MeTTa REPL):
; -------------------------------------------------------
; Should unify as APPROVED
(validate-property "prop-101" $status)
; -> $status = "APPROVED"

; Should unify as NEEDS_MORE_INFO (missing docs)
(validate-property "prop-202" $status $reason)
; -> $status = "NEEDS_MORE_INFO", $reason = "Missing required documents"

; Should unify as NEEDS_MORE_INFO (KYC pending)
(validate-property "prop-303" $status $reason)
; -> $status = "NEEDS_MORE_INFO", $reason = "KYC pending"
This gives you working sample data so you can watch the inference fire.
Want me to include a mini README (what to load first, how to query, and how to extend) so your teammates can immediately test it?







You said:
; Rules for property valuation

; Base price per sqft for different locations
(= (base-rate "Delhi") 8000)
(= (base-rate "Mumbai") 12000)
(= (base-rate "Bengaluru") 7500)

; Feature multipliers
(= (feature-multiplier "new_construction") 1.2)
(= (feature-multiplier "parking") 1.1)
(= (feature-multiplier "garden") 1.15)

; Calculate the estimated value
(= (calculate-value $prop-id)
   (let* (($area (area-sqft $prop-id))
          ($loc (location $prop-id))
          ($base-rate (base-rate $loc))
          ($base-value (* $area $base-rate)))
         ; For simplicity, we apply one multiplier. A real system could compose them.
         (if (has-feature $prop-id $feature)
             (* $base-value (feature-multiplier $feature))
             $base-value)))

; Define the valuation range based on the calculated value
(= (get-valuation-range $prop-id)
   (let $value (calculate-value $prop-id)
        (list (* $value 0.9) ; Lower bound (90%)
              (* $value 1.1) ; Upper bound (110%)
        )))

make it complete by adding more popular cities


ChatGPT said:
Here’s a fuller valuation rules file that keeps your same style but broadens the city coverage and still stays simple enough to run in a MeTTa REPL:

metta
Copy code
; -------------------------------------------------------
; Property Valuation Agent – MeTTa knowledge/rules
; -------------------------------------------------------

; === Base price per sqft (₹) by city ===
(= (base-rate "Delhi")       8000)
(= (base-rate "Mumbai")      12000)
(= (base-rate "Bengaluru")   7500)
(= (base-rate "Chennai")     7000)
(= (base-rate "Hyderabad")   6800)
(= (base-rate "Pune")        7200)
(= (base-rate "Kolkata")     6500)
(= (base-rate "Ahmedabad")   6000)
(= (base-rate "Gurugram")    9500)
(= (base-rate "Noida")       7800)
(= (base-rate "Jaipur")      5800)
(= (base-rate "Lucknow")     5500)
(= (base-rate "Chandigarh")  8000)

; Default catch-all (if no explicit city match)
(= (base-rate "OTHER")       5000)

; === Feature multipliers ===
(= (feature-multiplier "new_construction") 1.2)
(= (feature-multiplier "parking")          1.1)
(= (feature-multiplier "garden")           1.15)
(= (feature-multiplier "corner_plot")      1.05)
(= (feature-multiplier "swimming_pool")    1.25)
(= (feature-multiplier "clubhouse")        1.08)

; === Core Valuation Rule ===
; Computes estimated value from area, location and (optionally) a feature.
; For simplicity, applies at most one multiplier – you can chain later if needed.
(= (calculate-value $prop-id)
   (let* (
           ($area       (area-sqft $prop-id))
           ($loc        (location $prop-id))
           ; fallback if city not in table
           ($base       (if (base-rate $loc) (base-rate $loc) (base-rate "OTHER")))
           ($base-value (* $area $base))
         )
        (if (has-feature $prop-id $feature)
            (* $base-value (feature-multiplier $feature))
            $base-value)))

; === Valuation Band (±10%) ===
(= (get-valuation-range $prop-id)
   (let $value (calculate-value $prop-id)
        (list (* $value 0.9)    ; lower
              (* $value 1.1)))  ; upper

; -------------------------------------------------------
; Example facts (to test quickly)
; -------------------------------------------------------
; (area-sqft "prop-501")      1450
; (location "prop-501")       "Pune"
; (has-feature "prop-501"     "garden")
;
; Query:
; (calculate-value "prop-501" $val)
; (get-valuation-range "prop-501" $range)
Add more cities: just append (= (base-rate "CityName") number)

Multiple features: change the simple if to a fold that multiplies all (feature-multiplier …) values.

Would you also like me to show a multi-feature version (so you can handle, e.g., parking + garden together) instead of only one?







You said:
yes show


ChatGPT said:
Here’s the same valuation file refactored so you can apply any number of features instead of just one.
It uses a little recursive helper rule to walk through the feature list and multiply everything together.

metta
Copy code
; -------------------------------------------------------
; Property Valuation Agent – Multi-Feature Version
; -------------------------------------------------------

; === Base price per sqft (₹) by city ===
(= (base-rate "Delhi")       8000)
(= (base-rate "Mumbai")      12000)
(= (base-rate "Bengaluru")   7500)
(= (base-rate "Chennai")     7000)
(= (base-rate "Hyderabad")   6800)
(= (base-rate "Pune")        7200)
(= (base-rate "Kolkata")     6500)
(= (base-rate "Ahmedabad")   6000)
(= (base-rate "Gurugram")    9500)
(= (base-rate "Noida")       7800)
(= (base-rate "Jaipur")      5800)
(= (base-rate "Lucknow")     5500)
(= (base-rate "Chandigarh")  8000)
(= (base-rate "OTHER")       5000) ; fallback

; === Feature multipliers ===
(= (feature-multiplier "new_construction") 1.2)
(= (feature-multiplier "parking")          1.1)
(= (feature-multiplier "garden")           1.15)
(= (feature-multiplier "corner_plot")      1.05)
(= (feature-multiplier "swimming_pool")    1.25)
(= (feature-multiplier "clubhouse")        1.08)

; === Recursive helper ===
; Multiply all multipliers in a list of features
(= (accum-multiplier (cons $f $rest))
   (* (feature-multiplier $f)
      (accum-multiplier $rest)))

(= (accum-multiplier nil) 1)   ; base case: no more features

; === Calculate full value ===
; Pulls list of features from (features $prop-id) -> (list ...)
(= (calculate-value $prop-id)
   (let* (
           ($area       (area-sqft $prop-id))
           ($loc        (location $prop-id))
           ($base       (if (base-rate $loc) (base-rate $loc) (base-rate "OTHER")))
           ($base-value (* $area $base))
           ($features   (features $prop-id))   ; expect list, or nil
           ($mult       (accum-multiplier $features))
         )
         (* $base-value $mult)))

; === Valuation Band (±10%) ===
(= (get-valuation-range $prop-id)
   (let $value (calculate-value $prop-id)
        (list (* $value 0.9)
              (* $value 1.1))))
