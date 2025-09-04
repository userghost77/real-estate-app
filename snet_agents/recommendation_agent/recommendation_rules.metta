; -------------------------------------------------------
; Property Recommendation Agent – MeTTa rules
; -------------------------------------------------------

; === Core Similarity ===
; Two properties are similar if:
;   - same location
;   - same property type (flat / villa / plot)
;   - price per sqft within ±15%
;   - bedrooms difference <= 1 (if bedrooms known)
;   - and they are not literally the same property
(= (is-similar $propA $propB)
   (And (== (location $propA) (location $propB))
        (== (type $propA)     (type $propB))
        (within-price-band $propA $propB)
        (bedroom-close $propA $propB)
        (Not (== $propA $propB))))

; Price band helper – ±15%
(= (within-price-band $propA $propB)
   (let* (($pa (calculate-value $propA))
          ($pb (calculate-value $propB))
          ($low (* $pa 0.85))
          ($high (* $pa 1.15)))
        (And (>= $pb $low) (<= $pb $high))))

; Bedroom closeness helper
(= (bedroom-close $propA $propB)
   (let* (($ba (bedrooms $propA))
          ($bb (bedrooms $propB)))
        (<= (abs (- $ba $bb)) 1)))

; === Base Viewing Facts ===
; (viewed-by "user-1" "prop-10") etc.

; === Recommendation ===
; Suggest $rec to $user if:
;   1. $user has viewed some $viewed-prop
;   2. $rec is similar
;   3. $user has NOT viewed $rec
;   4. $rec is active (optional status)
(= (should-recommend $user $rec)
   (And (viewed-by $user $viewed-prop)
        (is-similar $viewed-prop $rec)
        (Not (viewed-by $user $rec))
        (is-active $rec)))

