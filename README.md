# github-add-user
Script to add a github user or users to one or more repositories as a collaborator.

This is adapted from miraculixx/github-add-user.  Real credit goes to github.com/miraculixx - my additions here are minor.

Enhancements are:

* Support for taking API token from a file (avoid credentials on command line).
* Support for specifying an Org.
* Support for specifying a GHE endpoint.
* Support for specifying permissions.
* Support for listing contributors as well as collaborators.

TO-DO is to either redo in Python or use a helper so the JSON responses can be more robustly parsed.

Note experimentation showed that the permissions parameter to the add collaborator API doesn't seem to work 
as a URL argument, hence the need to put it in the PUT body.

