#|
  This file is a part of TyNETv5/Radiance
  (c) 2013 TymoonNET/NexT http://tymoon.eu (shinmera@tymoon.eu)
  Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package :radiance-mod-db-introspect)

(admin:define-panel database database (:access-branch "admin.database.*" :menu-icon "fa-calendar" :menu-tooltip "Show all collections in the database" :lquery (template "db-introspect/database.html"))
  (uibox:fill-foreach
   (mapcar #'(lambda (collection) `(:name ,collection :records ,(length (db:select collection :all :limit -1)))) (db:collections))
   "tbody tr"))

(admin:define-panel collection database (:access-branch "admin.database.collection.*" :menu-icon "fa-table" :menu-tooltip "View collection contents" :lquery (template "db-introspect/collection.html"))
  (let ((selected (server:get "name")))
    (if selected
        (if (string= (server:post-or-get "action") "Delete")
            (uibox:confirm ((format NIL "Really drop the collection ~a and all its data?" selected))
               (progn
                 (db:drop selected)
                 (server:redirect "/database/database"))
               (server:redirect "/database/database"))
            (display-collection selected))
        (server:redirect (server:referer)))))

(defun display-collection (name)
  ($ "h2" (text (concatenate 'string "Manage Collection " name)))
  (let ((fields (db:apropos name)))
    (loop with template = ($ "thead .template" (node))
       for name in fields
       collect ($ template (clone) (node) (text name)) into nodes
       finally (progn ($ nodes (insert-before template))
                      ($ template (remove))))
    (let* ((template ($ "tbody tr" (node)))
           (rows (db:iterate
                  name :all
                  #'(lambda (record)
                      (loop with row = ($ template (clone) (node))
                         with inner-template = ($ row ".template" (node))
                         for name in fields
                         collect ($ inner-template (clone) (node) (text (cdr (assoc name record :test #'string-equal)))) into nodes
                         finally (progn ($ nodes (insert-before inner-template))
                                        ($ inner-template (remove))
                                        (uibox:fill-all row record)
                                        (return row)))))))
      ($ rows (insert-before template))
      ($ template (remove))
      ($ "input[name=\"name\"]" (val name)))))

(admin:define-panel record database (:access-branch "admin.database.collection.record.*" :menu-icon "fa-list-alt" :menu-tooltip "View record contents" :lquery (template "db-introspect/record.html"))
  (let* ((selected (or (server:post "selected[]")
                       (server:get "id")))
         (name (server:post-or-get "name"))
         (return-url (format NIL "/database/collection?name=~a" name)))
    (if (and selected name)
        (string-case:string-case ((server:post-or-get "action"))
          ("Delete" (uibox:confirm ("Are you sure you want to delete the selected record(s)?")
                      (progn
                        (dolist (id (if (listp selected) selected (list selected)))
                          (db:remove name (db:query (:= "_id" id))))
                        (server:redirect return-url))
                      (server:redirect return-url)))
          ("Save" (save-record name selected))
          ("Edit" (if (server:post "_id")
                      (progn (save-record name selected)
                             (server:redirect return-url))
                      (display-record name (if (listp selected) (first selected) selected))))
          (T (server:redirect (server:referer))))
        (server:redirect (server:referer)))))

(defun display-record (collection id)
  ($ "h2" (text (concatenate 'string "Edit record " id " of " collection)))
  (let ((model (dm:get-one collection (db:query (:= "_id" id)))))
    (if model
        (loop with template = ($ ".template" (node))
           for key in (db:apropos collection)
           for val = (dm:field model key)
           for node = ($ template (clone) (node))
           do ($ node "label" (text key))
             ($ node "input" (attr :value val :name key))
             ($ node (insert-before template))
           finally ($ template (remove)))
        (uibox:notice "No such record found!" :type :error))))

(defun save-record (collection id)
  (with-model model (collection (db:query (:= "_id" id)) :save T)
    (dolist (field (db:apropos collection))
      (setf (getdf model field) (server:post field)))
    (uibox:notice "Record updated.")))