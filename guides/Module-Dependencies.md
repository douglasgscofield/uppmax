Managing Module Dependencies
============================

On UPPMAX and other clusters, one can frequently encounter problems with software tools that are not caused by the tools themselves, but instead are caused by conflicting dependencies between multiple tools in concurrent use.

This is easiest to show with an example, where the [cutadapt](https://cutadapt.readthedocs.org/en/stable/) tool works, and then doesn't, after a conflicting module load.

    milou-b: ~ $ module load bioinfo-tools cutadapt/1.8.0
    milou-b: ~ $ cutadapt -h
    cutadapt version 1.8
    Copyright (C) 2010-2015 Marcel Martin <marcel.martin@scilifelab.se>

        cutadapt -a ADAPTER [options] [-o output.fastq] input.fastq
    ...

    milou-b: ~ $ module load python/2.7
    milou-b: ~ $ cutadapt -h
    /sw/comp/python/2.7.6_milou/bin/python: error while loading shared libraries: libpython2.7.so.1.0: cannot open shared object file: No such file or directory

The message results from a conflict in the version of python expected by `cutadapt` in the `cutadapt/1.8.0` module -- a conflict in module dependencies.  We back up and learn more about the problem by examining what is loaded when we load `cutadapt/1.8.0`.

    milou-b: ~ $ module unload python cutadapt
    milou-b: ~ $ module list
     
    Currently Loaded Modules:
      1) uppmax   2) bioinfo-tools
    milou-b: ~ $ module load cutadapt/1.8.0
    milou-b: ~ $ module list
     
    Currently Loaded Modules:
      1) uppmax   2) bioinfo-tools   3) cutadapt/1.8.0   4) python/2.7.6

We see that loading `cutadapt/1.8.0` also resulted in loading `python/2.7.6`, and unloading (via `module unload`) the `cutadapt/1.8.0` module will also unload `python/2.7.6`.

This is a dependency, and if the python module is unloaded or a different version is loaded, as we did by loading `python/2.7` above, problems will start to appear.

    milou-b: ~ $ module load cutadapt/1.8.0 python/2.7
    milou-b: ~ $ module list

    Currently Loaded Modules:
      1) uppmax   2) bioinfo-tools   3) cutadapt/1.8.0   4) python/2.7

This is particularly a problem for python- and Perl-based tools, for which different tools may depend upon different interpreter versions, or (more likely) the predominant version in use at installation was different, say python 2.7.6 *vs* 2.7.9.

This is also a problem when using two modules that themselves depend on different versions of a mutual dependency.  In such cases, the source of the conflict might be less obvious.

    milou-b: ~ $ module list

    Currently Loaded Modules:
      1) uppmax   2) bioinfo-tools
    milou-b: ~ $ module load cutadapt/1.8.0
    milou-b: ~ $ module list

    Currently Loaded Modules:
      1) uppmax   2) bioinfo-tools   3) cutadapt/1.8.0   4) python/2.7.6
    milou-b: ~ $ module load pysam/0.8.3-py27

    The following have been reloaded with a version change:
      1) python/2.7.6 => python/2.7

    milou-b: ~ $ module list

    Currently Loaded Modules:
      1) uppmax   2) bioinfo-tools   3) cutadapt/1.8.0   4) pysam/0.8.3-py27   5) python/2.7

Note the message about changing the python version while loading `pysam/0.8.3-py27`.  This will (as we saw above) prevent us from using `cutadapt/1.8.0` while `pysam/0.8.3-py27` is loaded.

The application experts at UPPMAX try to reduce the likelihood of such issues by standardising on particular interpreter and compiler versions during installation. This is not always possible, as important bug fixes or performance enhancements might be available in later versions of an interpreter, or a tool requires specific features introduced in a later version.

At times we provide module versions that depend upon different interpreter versions, such as for versions of the `pysam` module: `pysam/0.8.3-py27` depends on `python/2.7`, while the `pysam/0.8.3` module depends on `python/2.7.6`, and would be a much better choice in this example.  In general, however, there is little time available to reinstall already-installed tools where the only change in installation is in the interpreter version used.

Tools themselves can do much more to manage their own dependencies independently.  For example, python-based tools can set up their own virtual environment so that the interpreter, libraries and packages used by the tool are specific versions fixed during installation.  Unfortunately, this type of robust installation procedure is not common.

Ultimately, it is the user's responsibility to manage dependency conflicts in tools loaded via the module system.  Here are a few tips to help with this.

1. Check dependencies first
---------------------------

Check dependencies of modules by using `module list` before and after a module is loaded.  This will give you a clue to whether dependency problems are likely.  When loading multiple modules, **pay attention to messages** like the one above:

    The following have been reloaded with a version change:
      1) python/2.7.6 => python/2.7


2. Use tool versions with no dependency conflicts
-------------------------------------------------

Put the knowledge gained by using `module list`, together with our limited documentation at <http://www.uppmax.uu.se/installed-software>, to figure out which versions of different modules have compatible dependencies.  After you find `pysam` on that page, you will see that `pysam/0.8.3` is the version that has `python/2.7.6` as its dependency, while `pysam/0.8.3-py27` has `python/2.7` as its dependency, and that conflicts with what `cutadapt/1.8.0` needs.  We should have loaded `pysam/0.8.3` instead.

We have a few such dependencies listed for modules on the Installed Software page, but this information is incomplete and likely always will be.  By using `module list` as noted above, you will have complete information.


3. Load and unload modules as you need them
-------------------------------------------

Tools within different modules can only have problems arising from conflicting dependencies if the different modules are both loaded at the same time.  It is better to load and unload modules as you need them.  This can be particularly helpful with python- and Perl-based tools.

We often see (and I often write) SLURM scripts that contain a preamble that loads several modules at once, even when the modules are not required simultaneously.  This practice is helpful for self-documentation, but is also a potential source of conflicting dependencies.

For example, a SLURM script for a variant-calling pipeline starting from raw sequence data does not need to load a read-mapper module while performing QC with tools loaded with the `cutadapt`, `Trimmomatic`, or `FastQC` modules; does not need to have any of these modules loaded while mapping reads and creating BAM files with tools from the `bwa` and `samtools` modules; and does not need a read mapper module loaded when manipulating BAM files with `Picard` or calling variants with `GATK`.

Some modules simply won't create conflicts, for example current versions of `GATK` won't conflict with python-based tools, and conflicts are less common between compiled tools such as `BEDTools` or `bowtie2`.

