Scripts that could be useful for users at Uppmax.

### blast_wrapper.pl

**Not yet in working order**

Produce a few SLURM scripts to package up a multifasta file into multiple jobs
and collect results, hacked together based on the OrthoMCL wrapper script.

### check-project-access.sh

Check whether the project and current user have permissions set to be a good
neighbour.  Scan through an Uppmax project tree, checking for directories and
files that do not have the group ID of the project and directories that do not
have the 'set group id' bit set (`chmod g+s`).  Also checks whether user umask
is set to `0007`, which allows for project member access while ensuring project
privacy.
