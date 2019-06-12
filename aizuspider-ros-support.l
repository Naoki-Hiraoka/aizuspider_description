(require :aizuspider-interface
         "package://aizuspider_description/aizuspider-interface.l")

(ros::roseus-add-srvs "aizuspider_description")

(ros::roseus "aizuspider_ros_support")

(setq *namespace* "AizuSpiderAA")
(when (ros::has-param "~namespace")
  (setq *namespace* (ros::get-param "~namespace")))

(aizuspider-init :namespace *namespace*)

(defun grasp-callback (req)
  (let ((pos (send req :position))
        (tm (send req :time))
        (wait (send req :wait))
        (res (send req :response))
        )
    (send *robot* :angle-vector
          (send *ri* :state :reference-vector))
    (send *robot* :rarm :hand-f1 :joint-angle pos)
    (send *robot* :rarm :hand-f2 :joint-angle pos)
    (send *robot* :rarm :hand-f3 :joint-angle pos)
    (send *ri* :angle-vector (send *robot* :angle-vector) tm)
    (when wait
      (send *ri* :wait-interpolation))
    res
    ))

(defun ik-callback (req)
  (let ((cds (ros::tf-pose->coords (send req :pose)))
        (tgt
         (send (car (send *robot* :links)) :copy-worldcoords))
        (move (send req :move))
        (wait (send req :wait))
        (res (send req :response))
        )
    (send tgt :transform cds)

    (send *robot* :angle-vector
          (send *ri* :state :reference-vector))
    (when (send *robot* :rarm :inverse-kinematics cds)
      (send res :success t)
      (send res :angles
            (send *robot* :angle-vector))
      (when (> move 0)
        (send *ri* :angle-vector
              (send *robot* :angle-vector) move)
        (when wait (send *ri* :wait-interpolation)))
      )
    res
    ))

(ros::advertise-service (format nil "~A/grasp" *namespace*)
                        aizuspider_description::Grasp
                        #'grasp-callback)

(ros::advertise-service (format nil "~A/solve_ik" *namespace*)
                        aizuspider_description::SolveIK
                        #'ik-callback)
(ros::rate 0.01)
(while (ros::ok)
  (ros::spin-once)
  )