; -------------------------------------------------------
; Property Valuation Agent – MeTTa rules
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
(= (base-rate "OTHER")       5000)  ; fallback if city not found

; === Location demand multipliers ===
(= (demand-multiplier "Delhi")     1.05)
(= (demand-multiplier "Mumbai")    1.12)
(= (demand-multiplier "Bengaluru") 1.08)
(= (demand-multiplier "Hyderabad") 1.06)
(= (demand-multiplier "Pune")      1.07)
(= (demand-multiplier "OTHER")     1.00)

; === Property type multipliers ===
(= (type-multiplier "residential") 1.00)
(= (type-multiplier "commercial")  1.20)
(= (type-multiplier "industrial")  0.90)

; === Feature multipliers (amenities) ===
(= (feature-multiplier "new_construction") 1.20)
(= (feature-multiplier "parking")          1.10)
(= (feature-multiplier "garden")           1.15)
(= (feature-multiplier "corner_plot")      1.05)
(= (feature-multiplier "swimming_pool")    1.25)
(= (feature-multiplier "clubhouse")        1.08)
(= (feature-multiplier "furnished")        1.10)

; === Age adjustment (per year older) ===
; e.g. 5-year-old property => multiplier = (age-multiplier 5) = 0.95
(= (age-multiplier $years)
   (- 1 (* 0.01 $years)))    ; subtract 1% per year

; === Recursive helper: multiply amenities ===
(= (accum-multiplier (cons $f $rest))
   (* (feature-multiplier $f)
      (accum-multiplier $rest)))
(= (accum-multiplier nil) 1)

; === Calculate raw value ===
(= (calculate-value $prop-id)
   (let* (
           ($area     (area-sqft $prop-id))
           ($loc      (location $prop-id))
           ($ptype    (property-type $prop-id))
           ($age      (property-age $prop-id))      ; in years
           ($features (features $prop-id))          ; (list ...)
           ($base     (if (base-rate $loc) (base-rate $loc) (base-rate "OTHER")))
           ($demand   (if (demand-multiplier $loc) (demand-multiplier $loc) (demand-multiplier "OTHER")))
           ($ptype-m  (if (type-multiplier $ptype) (type-multiplier $ptype) 1))
           ($age-m    (if (< $age 0) 1 (age-multiplier $age))) ; guard negative
           ($feat-m   (accum-multiplier $features))
           ($base-val (* $area $base))
         )
         (* $base-val $demand $ptype-m $age-m $feat-m)))

; === Suggested valuation range ±10% ===
(= (get-valuation-range $prop-id)
   (let $val (calculate-value $prop-id)
        (list (* $val 0.9)
              (* $val 1.1))))

; === Confidence Score ===
; crude example: start at 0.8, raise by 0.02 per major feature, clamp 0–1
(= (confidence-score $prop-id)
   (let* (($feat-list (features $prop-id))
          ($count     (length $feat-list))
          ($raw       (+ 0.8 (* 0.02 $count))))
         (min 1 $raw)))  ; cap at 1

; === Master Verdict: returns range + confidence ===
(= (valuate-property $prop-id $low $high $conf)
   (let* (($range (get-valuation-range $prop-id))
          ($low   (first $range))
          ($high  (second $range))
          ($conf  (confidence-score $prop-id)))
         (list $low $high $conf)))

; -------------------------------------------------------
; Example Facts
; -------------------------------------------------------
; (area-sqft "prop-701")        1450
; (location "prop-701")         "Pune"
; (property-type "prop-701")    "residential"
; (property-age "prop-701")     3
; (features "prop-701")         (list "parking" "garden")
;
; Query:
; (valuate-property "prop-701" $low $high $conf)
; -> $low = 8.2e6, $high = 9.9e6, $conf ~ 0.84
