; -------------------------------------------------------
; Property Recommendation Agent – MeTTa rules
; -------------------------------------------------------

; === Core Similarity ===
; "Content-based" match: same location, same property type
(= (content-similar $propA $propB)
   (And (== (location $propA) (location $propB))
        (== (property-type $propA) (property-type $propB))
        (Not (== $propA $propB))))

; Optional tighter band on price per sqft ±15%
(= (within-price-band $propA $propB)
   (let* (($pa (calculate-value $propA))
          ($pb (calculate-value $propB))
          ($low (* $pa 0.85))
          ($high (* $pa 1.15)))
        (And (>= $pb $low) (<= $pb $high))))

; Bedrooms within ±1 (if both defined)
(= (bedroom-close $propA $propB)
   (let* (($ba (bedrooms $propA))
          ($bb (bedrooms $propB)))
        (<= (abs (- $ba $bb)) 1)))

; "Similar" means basic content overlap + optional price & bedroom proximity
(= (is-similar $propA $propB)
   (And (content-similar $propA $propB)
        (within-price-band $propA $propB)
        (bedroom-close $propA $propB)))

; -------------------------------------------------------
; Buyer behavior features
; -------------------------------------------------------

; Helper: does user linger on luxury props? (e.g. avg view time > threshold)
(= (luxury-leaning $user)
   (> (avg-view-time-luxury $user) 120))  ; seconds threshold

; Helper: has user saved many furnished props?
(= (prefers-furnished $user)
   (> (count-saved-with-feature $user "furnished") 2))

; Investment profile: small-ticket vs premium
(= (small-investor $user)
   (< (avg-investment $user) 5000000))    ; < 50L INR
(= (premium-investor $user)
   (>= (avg-investment $user) 5000000))

; -------------------------------------------------------
; Master recommendation rule
; -------------------------------------------------------

; Suggest $rec to $user if:
; 1. user has viewed some $seed
; 2. $rec is similar in content
; 3. user hasn’t already viewed $rec
; 4. property is active
; 5. rec aligns with buyer tendencies (amenities / luxury / investment)
(= (should-recommend $user $rec)
   (And
     (viewed-by $user $seed)
     (is-similar $seed $rec)
     (Not (viewed-by $user $rec))
     (is-active $rec)
     (aligns-with-behavior $user $rec)))

; -------------------------------------------------------
; Behavior alignment logic
; -------------------------------------------------------

; Default alignment if nothing special flags
(= (aligns-with-behavior $user $prop) true)

; Luxury inclination
(= (aligns-with-behavior $user $prop)
   (And (luxury-leaning $user)
        (luxury-segment $prop)))

; Furnished preference
(= (aligns-with-behavior $user $prop)
   (And (prefers-furnished $user)
        (has-feature $prop "furnished")))

; Small-ticket investor → prefer fractional / low-cost
(= (aligns-with-behavior $user $prop)
   (And (small-investor $user)
        (fractionalizable $prop)
        (< (calculate-value $prop) 3000000)))

; Premium investor → prefer high-value, whole assets
(= (aligns-with-behavior $user $prop)
   (And (premium-investor $user)
        (>= (calculate-value $prop) 10000000)
        (whole-ownership $prop)))

; -------------------------------------------------------
; Example Facts (for testing)
; -------------------------------------------------------
; (viewed-by "user-1" "prop-101")
; (location "prop-101")        "Mumbai"
; (property-type "prop-101")   "residential"
; (bedrooms "prop-101")        3
;
; (location "prop-202")        "Mumbai"
; (property-type "prop-202")   "residential"
; (bedrooms "prop-202")        2
; (calculate-value "prop-202") 9500000
; (is-active "prop-202")       true
;
; (avg-view-time-luxury "user-1") 180
; (count-saved-with-feature "user-1" "furnished") 3
; (avg-investment "user-1")    7000000
;
; Query:
; (should-recommend "user-1" "prop-202")
; -> true  (content match + luxury inclination + furnished pref)

; -------------------------------------------------------
; Extension Ideas
; -------------------------------------------------------
; - incorporate collaborative filtering scores
; - decay older user activity
; - geo-radius search instead of strict city match
; -------------------------------------------------------
