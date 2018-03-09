# AbstractFirebaseLogin

This was an attempt to abstract most of Firebase auth into a separate component. This could be a pod that allows a project to not include any of the below pods and still Auth with all of them.

Currently it wraps:
- FirebaseAuth, Firebase email auth
- GoogleSignIn, Google sign in
- FBSDKLoginKit, Facebook auth (haven't added the keys for this into the example project)
