#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

my $o_jobs = 1;
my $maxjobs = 10;
my $o_threads = 8;
my $maxcores = 16;
my $o_time = "8:00:00";
my $o_email;
my $o_Account;
my $o_module = "blast/2.6.0+";
my $o_blastcommand;
my $o_input;
my $o_dryrun = 1;
my $o_concatenate = 1;

my $usage = "
blast_wrapper.pl  OPTIONS  -i file.fa

OPTIONS

--input/-i FILE         Input file in multifasta format
--jobs INT              Number of jobs, file.fa is divided into this many chunks [$o_jobs]
                        Assuming $maxjobs jobs maximum.
--threads-per-job INT   Number of threads per blast job, same as number of cores / job [$o_threads]
                        Assuming $maxcores cores / node.
--time STRING           Runtime for each blast job [$o_time]
--email STRING          Email address to use for each blast job [$o_email]
--Account STRING        SLURM account to specify [$o_Account]
--module STRING         Blast module to load [$o_module]
--blast-command STRING  The blast command to use when blasting each chunk of file.fa.
                        This will contain the blast program, e-value, outformat, etc.
                        The chunk of file.fa to be blasted will be added with the
                        -query option, so don't include a -query option in this command.
                        Also, don't include -num_threads as that will be added too.
--concatenate           Concatenate the blast results for each chunk of file.fa.
";

GetOptions("i|input=s" => \$o_input,
           "jobs=i" => \$o_jobs,
           "threads-per-job=i" => \$o_threads,
           "time=s" =>\$o_time,
           "email=s" =>\$o_email,
           "Account=s" =>\$o_Account,
           "module=s" =>\$o_module,
           "n|dryrun" =>\$o_dryrun,
           "blast-command=s" =>\$o_blast_command,
           "concatenate:1" =>\$o_concatenate) or die $usage;

die $usage if ! $o_input or ! -f $o_input or ! $o_blast_command or ! $o_module or
    ! $o_email or ! $o_Account or ! $o_time or $o_jobs <= 0 or $o_jobs >= 10 or
    $o_threads <= 0 or $o_threads >= $maxcores;

# individual chunk blast script

# wrapup script

# split and submit script, captures SLURM job IDs for wrapup script
open (my $script_pre, ">", "split_submit.sh");
say $script_pre << "__SCRIPT_PRE__"
#!/bin/bash
module load ucsc-utilities/v334
faSplit sequence $o_input $o_jobs ${o_input}_chunk
__SCRIPT_PRE__

while (my $path = <>) {
    chomp $path;
    ++$fullpaths{$path};
    next if $path !~ /\.(fastq|fq)\.(gz|bz2|xz)$/;  # not *.fastq.{gz,bz2,xz}
    my (undef, $directories, $file) = File::Spec->splitpath($path);
    $directories =~ s/\/$//;  # remove trailing / if present
    ++$files{$file};
    push @{$map{$file}}, $path;
    if ($o_trimsuffix) {
        # split filename by dot, join after removing the last $o_trimsuffix
        my @t = split(/\./, $file);
        if (scalar @t > $o_trimsuffix) {
            pop @t for 1 .. $o_trimsuffix;
            my $filetrim = join('.', @t);
            ++$files_trim{$filetrim};
            push @{$map{$filetrim}}, $path;
        }
    }
    my @dirs = File::Spec->splitdir($directories);
    if (scalar @dirs) {
        my $dirfile = File::Spec->catfile($dirs[$#dirs], $file);
        ++$dirfiles{$dirfile};
        push @{$map{$dirfile}}, $path;
    }
}
sub check_duplicates($$) {
    my ($hash, $tag) = @_;
    for my $k (sort keys %{$hash}) {
        if ($hash->{$k} > 1) {
            print "duplicate $tag x$hash->{$k}: $k\n";
            if ($o_verbose) {
                 print "\t$_\n" foreach (@{$map{$k}});
            }
            ++$dups_seen;
        }
    }
}
check_duplicates(\%fullpaths,  "full input path");
check_duplicates(\%files,      "filename");
check_duplicates(\%files_trim, "filename removing $o_trimsuffix suffixes") if $o_trimsuffix;
check_duplicates(\%dirfiles,   "directory/filename");

exit 1 if $dups_seen;

GetOptions(

#!/bin/bash

BLAST_THREADS=4
BLAST_TIME="10:00:00"
ACCOUNT=
EMAIL=
SPLIT_DEFAULT=50

module load bioinfo-tools
module load OrthoMCL/2.0.9
#module load mcl/14-137   
#module load sqlite/3.16.2
#module load blast/2.5.0+
#module load perl/5.18.4
#module load BioPerl/1.6.924_Perl5.18.4

OPTS=$(getopt -o Cc:p:u:s:o:a:e:t: -l "CreateConfig,config:,protein_dir:,uniqid:,split:,ortho_db:,account:,email:,time:" -n $0 -- "$@")
if [ $? -ne 0 ]
then
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -C|--CreateConfig) 
          shift; 
          CREATE_ORTHOMCL_CONFIG='yes';
          ;;
        -c|--config) 
          shift; 
          if [ -n "$1" ]; then
            echo "setting ORTHOMCL_CONFIG to be $1";
            ORTHOMCL_CONFIG=`readlink -f $1`;
            shift;
          fi
          ;;
        -p|--protein_dir) 
          shift; 
          if [ -n "$1" ]; then
            echo "setting PROTEIN_FASTA_DIR to be $1";
            PROTEIN_FASTA_DIR=`readlink -f $1`;
            #PROTEIN_FASTA_DIR=`realpath $1`; ##UPPMAX
            shift;
          fi
          ;;
        -u|--uniqid) 
          shift; 
          if [ -n "$1" ]; then
            echo "setting UNIQID to be $1";
            UNIQID=$1;
            shift;
          fi
          ;;
        -o|--ortho_db) 
          shift;      
          if [ -n "$1" ]; then
            echo "setting ORTHO_DB to be $1";
            ORTHO_DB=$1;
            shift;
          fi
          ;;
        -s|--split) 
          shift;      
          if [ -n "$1" ]; then
            echo "setting SPLIT to be $1";
            SPLIT=$1;
            shift;
          fi
          ;;
        -a|--account) 
          shift;      
          if [ -n "$1" ]; then
            echo "setting ACCOUNT (sbatch) to be $1";
            ACCOUNT="$1";
            shift;
          fi
          ;;
        -e|--email) 
          shift;      
          if [ -n "$1" ]; then
            echo "setting EMAIL (sbatch) to be $1";
            EMAIL="$1";
            shift;
          fi
          ;;
        -t|--time) 
          shift;      
          if [ -n "$1" ]; then
            echo "setting BLAST_TIME (sbatch) to be $1";
            BLAST_TIME="$1";
            shift;
          fi
          ;;
         --)
           shift;
           break;
           ;;

    esac
done

if [ ! $ORTHO_DB  ] ; then
  ORTHO_DB="orthoMCL.DB.`date +%Y.%m.%d`"; 
fi

if [[ "$CREATE_ORTHOMCL_CONFIG" ]] ; then
  echo "No config file specified"
  [[ ! -e orthomcl.config ]] || { echo "Cannot create example config file, 'orthomcl.config' exists"; exit 1; }
  echo "Creating an example config file in 'orthomcl.config'"
  echo "dbVendor=sqlite 
dbConnectString=DBI:SQLite:database=${ORTHO_DB}.sqlite
dbLogin=none
dbPassword=none
similarSequencesTable=SimilarSequences
orthologTable=Ortholog
inParalogTable=InParalog
coOrthologTable=CoOrtholog
interTaxonMatchView=InterTaxonMatch
percentMatchCutoff=50
evalueExponentCutoff=-5
oracleIndexTblSpc=NONE" > orthomcl.config
  exit 1
fi

if [ ! $PROTEIN_FASTA_DIR  ] ; then
  echo "Need to provide protein fasta dir"
  echo "${0##*/} -c [config file] -p [protein dir] -u [fasta header uniq id col] -o [ortho db name] -a [SLURM account] -e [SLURM email] -t [SLURM blast job time]

${0##*/} -C        creates an example config file to 'orthomcl.config' and then exits.  If
                   the -o option is used, the database within the example config file is given
                   that name.

config file  :     a config file for the SQLite3 databases. A config file must be specified.
                   [no default]
protein_dir  :     a directory of FASTA files. One FASTA for each species.
                   Each FASTA file must have a name in the form 'xxxx.fasta' 
                   where xxxx is a three or four letter unique taxon code.  
                   For example: hsa.fasta or eco.fasta
                   [no default]
db_name      :     input a name for the new database
                   [default=orthoMCL.DB.`date +%Y.%m.%d`]
uniq_id      :     a number indicating what field in the definition line contains
                   the protein ID.  Fields are separated by either ' ' or '|'. Any
                   spaces immediately following the '>' are ignored.  The first
                   field is 1. For example, in the following definition line, the
                   ID (AP_000668.1) is in field 4:  >gi|89106888|ref|AP_000668.1|
                   [default=2]
split        :     How many blast jobs do you want to run? 
                   [default=$SPLIT_DEFAULT]
account      :     SLURM account to charge for blast jobs
email        :     Email address for SLURM blast job notifications
time         :     Time limit to use for each SLURM blast job
                   [default=$BLAST_TIME]
"
  exit 1

fi
if [ ! $UNIQID  ] ; then
  ## guess
  UNIQID=2
fi

if [ ! $SPLIT  ] ; then 
  SPLIT=$SPLIT_DEFAULT
fi

ACCOUNT=${ACCOUNT:?SLURM account must be supplied with -a/--account}
EMAIL=${EMAIL:?SLURM notification email must be supplied with -e/--email}
BLAST_TIME=${BLAST_TIME:?SLURM blast job time limit must be supplied with -t/--time}

echo "PROTEIN_FASTA_DIR is $PROTEIN_FASTA_DIR"
echo "UNIQID id $UNIQID"
echo "ORTHO_DB is $ORTHO_DB"
echo "SPLIT is $SPLIT"
echo "ACCOUNT is $ACCOUNT"
echo "EMAIL is $EMAIL"
echo "BLAST_TIME is $BLAST_TIME"
echo "BLAST_THREADS is $BLAST_THREADS"


DIR=`pwd`
cd $DIR

if [ ! -e "$ORTHOMCL_CONFIG" ] ; then
  echo "Config file '$ORTHOMCL_CONFIG' not found"
  exit 1
fi

# drop db to get a clean slate
if [ -e "$ORTHO_DB.sqlite" ] ; then
  echo "Deleting $ORTHO_DB.sqlite"
  rm $ORTHO_DB.sqlite
fi


orthomclInstallSchema "$ORTHOMCL_CONFIG"



#make a copy of the original FASTA into dir called proteomes
if [ ! -d proteomes ]; then
 mkdir proteomes
 cd proteomes
 for file in $PROTEIN_FASTA_DIR/*.fasta
 do
  echo $file
  base=`basename $file .fasta`
  cp $file $base.pep 
 done
 cd ..
fi

# let orthoMCL clean the FASTAs
if [ ! -d cleanseq ] ; then
  mkdir cleanseq
  cd cleanseq
  for file in $DIR/proteomes/*.pep
   do
   base=`basename $file .pep`
   ## which field has a uniq ID? => 2
   orthomclAdjustFasta $base $file $UNIQID 
  done
  cd $DIR
  orthomclFilterFasta cleanseq 10 10
fi

## format goodProteins BLAST DB
if [ ! -e $DIR/goodProteins.fasta.pin ] ; then
  makeblastdb -in $DIR/goodProteins.fasta -title "OrthoMCLPeps" -dbtype prot
fi

## split up goodProteins into smaller FASTA
MAX=`expr $SPLIT - 1`
if [ ! -d $DIR/good_proteins_split ] ; then
  mkdir $DIR/good_proteins_split
fi
if [ ! -e $DIR/good_proteins_split/goodProteins_part_${MAX}.fasta ] ; then
  cd $DIR/good_proteins_split
  cp -s $DIR/goodProteins.fasta .
  split_fasta.pl $SPLIT goodProteins.fasta
  rm -f $DIR/good_proteins_split/goodProteins.fasta
fi 
cd $DIR 

## get ready for blast
#if [ ! -d $DIR/blastp_out ] ; then
#  mkdir $DIR/blastp_out
#fi
BLAST_Q=0
## consider adding check for qsub:  if [ `which qsub` != '' ] ; then
if [ ! -d $DIR/blastp_out ] ; then
  mkdir $DIR/blastp_out
  ## make array BLAST job
  BLAST_Q=1
  echo "#!/bin/bash -l
#SBATCH -A $ACCOUNT
#SBATCH -p core -n $BLAST_THREADS
#SBATCH -t $BLAST_TIME
#SBATCH -J run_split_blast_array
#SBATCH --mail-user=$EMAIL
#SBATCH --mail-type=ALL

PART=\${1:?Must provide fasta part number between 0 and $(($SPLIT - 1))}

module load bioinfo-tools
module load blast/2.5.0+

cd $DIR
blastp -query good_proteins_split/goodProteins_part_\${PART}.fasta -db goodProteins.fasta -num_threads $BLAST_THREADS -outfmt 6 -out $DIR/blastp_out/goodProteins_part_\${PART}_vs_goodProteins.BLASTP.tab -evalue 1e-3
" > $DIR/run_split_blast_array.sh

    echo "#!/bin/bash

JOBS=
for PART in \$(seq 0 $(($SPLIT - 1))) ; do
    echo submitting job for part \$PART
    JOBS=\"\$JOBS \$(sbatch $DIR/run_split_blast_array.sh \$PART | cut -f4 -d' ')\"
done
JOBS=\$(echo \$JOBS | sed -e 's/^ \+//' -e 's/ /,/g')

[[ \"\$JOBS\" ]] || { echo 'JOBS not set'; exit 1; }

CMD=\"sbatch --dependency=afterok:\$JOBS $DIR/finish.orthomcl.sh\"
echo \"wrapup slurm command is '\$CMD'\"
eval \$CMD;

" > $DIR/submit_split_blast_jobs.sh

fi


echo "#!/bin/bash -l
#SBATCH -A $ACCOUNT
#SBATCH -p core -n $BLAST_THREADS
#SBATCH -t 4-00:00:00
#SBATCH -J finish.orthomcl
#SBATCH --mail-user=$EMAIL
#SBATCH --mail-type=ALL

module load bioinfo-tools
module load OrthoMCL/2.0.9
#module load mcl/14-137   
#module load sqlite/3.16.2
#module load blast/2.5.0+
#module load perl/5.18.4
#module load BioPerl/1.6.924_Perl5.18.4

cd $DIR 

# This will reformat the BLAST data into something to load into the database
if [ ! -f goodProteins.BLASTP.bpo ]; then
 cat blastp_out/*tab > goodProteins.BLASTP.tab
 orthomclBlastParser goodProteins.BLASTP.tab cleanseq > goodProteins.BLASTP.bpo
fi

# Load the data into the DB
orthomclLoadBlast $ORTHOMCL_CONFIG goodProteins.BLASTP.bpo

# now run the ortholog/paralog initial finding
rm -rf pairs pairs.log 
orthomclPairs $ORTHOMCL_CONFIG  pairs.log cleanup=no

# Dump out the ortholog groups and the mclInput file
orthomclDumpPairsFiles $ORTHOMCL_CONFIG

# Run mcl for clustering
mcl mclInput  --abc -I 1.5 -o mclOutput.I15.out

# convert the MCL clusters into OrthoMCL groups
orthomclMclToGroups OG 1 < mclOutput.I15.out > mclGroups.I15.table
" > $DIR/finish.orthomcl.sh

