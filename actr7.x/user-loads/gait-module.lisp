;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;; Author      : Hyungseok Oh
;;; Address     : Cognitive Ergonomic Lab.
;;;             : Department of Industrial Engineering 
;;;             : Korea University
;;; 
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;; Filename    : gait-module.lisp
;;; Version     : 0.1
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; 2023.09.14
;;; ** Initial creation of the gait module
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Module to support parameters and device internals.

(defstruct gait-module
  support-latency
  swing-latency
  stride
  busy
  mode
  (lock (bt:make-recursive-lock "gait"))
  )


(defun create-gait-module (model-name)
  (declare (ignore model-name))
  (make-gait-module))

(defun reset-gait-module (gait)
  (declare (ignore gait))
  ;initial code
  )

(defun delete-gait-module (x)
  (declare (ignore x)))

(defun gait-module-params (gait param)
  (if (consp param)
    (case (car param)
      (:set-support-latency
       (setf (gait-module-support-latency gait) (cdr param)))
      (:set-swing-latency
       (setf (gait-module-swing-latency gait) (cdr param)))
      (:set-gait-mode
       (setf (gait-module-mode gait) (cdr param)))
      )
    (case param
      (:set-support-latency
       (gait-module-support-latency gait))
      (:set-swing-latency
       (gait-module-swing-latency gait))
      (:set-gait-mode
       (gait-module-mode gait))
      )))


(defun gait-module-queries (gait buffer query value)
  (case query
    (state
     (case value
       (busy (gait-module-busy gait))
       (free (not (gait-module-busy gait)))
       (error nil)
       (t (print-warning "Bad state query to the ~s buffer" buffer))))
    (t (print-warning "Invalid query ~s to the ~s buffer" query buffer))))




(define-module-fct 'gait
                   '(left-leg right-leg) 
  (list (define-parameter :set-support-latency 
               :documentation 
                  "set latency of double support"
               :default-value .11
               :valid-test 'nonneg
               :warning "Non-negative number"
               :owner t)
	(define-parameter :set-swing-latency
               :documentation 
                  "set latency of leg-swing"
               :default-value .41
               :valid-test 'nonneg
               :warning "Non-negative number"
               :owner t)
	(define-parameter :set-gait-mode 
               :documentation 
                  "set mode of gait movements (t: fixed)"
               :default-value nil
               :valid-test 'tornil
               :warning "T or nil"
               :owner t)
        )

   ;:request 'arm-module-requests
   :query 'gait-module-queries
   :version "1.0a1"
   :documentation "gait module for wearable device"
   :creation 'create-gait-module
   :reset 'reset-gait-module 
   :delete 'delete-gait-module
   :params 'gait-module-params
   )



;;;
;;; update motor module
;;;

(defstyle gait-movement () stride)

(defmethod feat-differences ((f1 gait-movement) (f2 gait-movement))
  (let ((count 0))
    (unless (equal (stride f1) (stride f2))
      (incf count))
    count))

(defmethod compute-exec-time ((m motor-module) (self gait-movement))
  (let ((gait (get-module gait)))
    (unless (gait-module-stride gait) (setf (gait-module-stride gait) 5))
    (if (gait-module-mode gait)
	(progn
	  (setf (gait-module-stride gait) 7)
	  )
      (progn
	(setf (gait-module-stride gait) 7)
	)
      )
    
  )
  (gait-module-swing-latency gait))

(defmethod compute-finish-time ((m motor-module) (self gait-movement))
  ;; no (0 second) longer than the execution time
  (+ 0 (exec-time self)))

(defmethod queue-output-events ((m motor-module) (self gait-movement))
  
  ;; Here we are just scheduling an event to print out the details
  ;; of the request at the execution time.
  
  (schedule-event-relative (exec-time self) 
                           'gait-print-style-info
                           :params (list (length self) (fprep-time self) (finish-time self)))
  
  ;; If the action were moving the hand then it should schedule that
  ;; here using the set-hand-position action with the value that was
  ;; stored in updated-pos by the prepare-features method.  Again, this
  ;; example does not need to do so, but this example is from the peck 
  ;; style movement:
  
  #|
  (schedule-event-relative (seconds->ms (exec-time self)) 'set-hand-position :time-in-ms t :module :motor 
                           :output nil :destination :motor 
                           :params (list (hand self) (updated-pos self)))
  |#
  )


;;; The function that will be called:

(defun gait-print-style-info (w x y) 
  ;(format t "Features are ~S~%~s seconds spent in preparation~%finishing after ~f seconds~%" w x y)
  )

;;; To add the new style use extend-manual-requests and provide the 
;;; style name and features as the description of the action and
;;; use the built-in function handle-style-request to process the
;;; requests.

(extend-manual-requests (gait-movement stride) handle-style-request)


;;;
;;; ADDITIONAL FUNCTIONS!!
;;;
