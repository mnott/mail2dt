# NAME

mail2dt - Docker Image for E-Mail Archiving

# VERSION

Version 0.0.1

# LICENCE AND COPYRIGHT

Copyright (c) 2020 Matthias Nott (mnott (at) mnsoft.org).

Licensed under [WTFPL](http://www.wtfpl.net/).


# INTRODUCTION

            This docker image creates a local IMAP server based on
            dovecot that you can use to transfer mails.

            For example, you can transfer mails between Outlook and
            Apple Mail, or you can use it to transfer Mail between
            those and DevonThink.

# SYNOPSIS

In all clarity, if you are happy with the following process that you have
to use if you do not use this program, you can skip this whole program
and go on with your life:

1. Click on the import icon on the left top of DevonThink
2. Right-Click on the list of email programs that DevonThink sees, and choose refresh
3. Click on the folder or folders that you want to import from
4. Click on one of those mails that are shown after a while, and press `Cmd+A` to select them all
5. Make sure you have chosen the right import target location, e.g. your Inbox, and click on Import
6. Switch over to your Mail client and delete those Mails there
7. Empty the Trash for your Email client.

As you can imagine, that process is rather quite annoying if you want to not
end up having a long email backlog of mails that are not yet in DevonThink.
It is tedious, repetitive, and hence there should be a better way.

To choose from only one source location in my email client (Outlook in my case),
I had already created a rule that would move just any mail or mails that I had selected,
into some folder - thereby, I would have to import those Mails only from that folder. But
that does not otherwise reduce the number of steps to do really.

So this program, or collection of scripts rather, chooses another way: It uses
the idea of creating a local mail server, a so-called IMAP server that runs on
your computer, as an intermediary. And since that server actually stores all
Mails on the file system of your computer, in a file format that DevonThink
can immediately understand, the basic task now is to use move the mails not
into a folder of your mail client, but actually into a folder of that new
mail server - to then move the files from there into DevonThink's Inbox.

There will hence be no distinct import process for DevonThink that you need
to manually start. To the contrary, you can just move the files into the IMAP
server right out of the Mail program - using an email rule similar to what I
spoke about before - and then within DevonThink, just hit one button to have
them not only imported, but also filed away if you want.

Sounds good, but also probably rather complicated. So to facilitate all of this,
I've wrapped the most complicated bit of it, the "running an email server on your
laptop" into a so-called Docker container. What that really means is that you do
not need to configure anything (unless you want to, and I am going to give details
on those options further below). You rather

1. Download and Install Docker
2. Download ("clone") this Git repository
3. Start the Docker Container
4. Configure your Mail Client to see the email server running inside the Docker Container
5. Copy one Script over to DevonThink's Script Directory
6. Restart DevonThink, and add the script to it's toolbar

Then in the future, you just do these simple steps to file away your Mails:

1. In your Mail application, Move the Mails to that email Server's Inbox
2. In DevonThink, click that new button on the toolbar


## Other Uses

Note that since this particular process is meant to facilitate the co-operation
between your Mail client and DevonThink, and DevonThink is a Mac application,
of course the whole process is very Mac specific. But as a bonus, the Docker
container containing the IMAP server is not at all Mac specific - it would
run just fine on another Operating system, and you could use it to, e.g.,
transfer Mails between two different kinds of Mail clients: For example,
people tend to struggle with getting their Mails out of Outlook and into
some other program. Using the intermediary IMAP server that comes within
this Docker container makes this a very simple thing: You just configure
the source and target Mail clients to connect to that server.


## INSTALLATION


### Prerequisites

#### Docker and Docker-Compose

Head over to [Docker](https://hub.docker.com/editions/community/docker-ce-desktop-mac/),
if you have not already done so. Install Docker on your machine, and run it. Docker
is a program that can run other stuff in an isolated form, similar to a virtual
machine, but without all the overhead that such a virtual machine would typically
consume.

* **Note:** If you would run Docker on Unix, you should use your distribution's preferred
way to install Docker, and you would also install `docker-compose`. That one comes
bundled with the Docker version for Mac, but e.g. on Ubuntu, it is a separate download.
* **Note:** On Windows, you would download Docker from
[here](https://hub.docker.com/editions/community/docker-ce-desktop-windows/).
* **Note:** On Unix or Windows based machines, before installing Docker, make
sure that you have switched on Virtualization in your BIOS
(the feature is often under either Configuration or Security, and
is often called Intel Virtualization Technology and VT-d Feature: Enable both).
If you fail to do this, the image may not start up.


#### Git

##### If you don't want to use Git

If you do not want to use Git regularly, you can just download this whole repository
into it's own directory. So for that, you would click
[here](https://github.com/mnott/mail2dt/archive/master.zip), download that zip file,
extract it to your home folder so that you essentially get a folder

	~/mail2dt

Then, head over to the configuration part below.

##### If you want to use Git

Of course, using Git has some advantages; for instance, you can more easily keep track
of changes to the program. Also it just makes you look so much more competent. So of
course, just install [Git](https://git-scm.com/download).

* **Note:** If you are working on a Windows system, make sure
to configure Git, when it installs, to *not automatically* convert
Line Ends ("CR/LF"). Shouly you have configured it wrongly, you can
do this on the command line:

	    git config --global core.autocrlf false

Finally, you open a command line and do this:

    cd ~
    git clone https://github.com/mnott/mail2dt
    cd mail2dt

### Summary of the Prerequisites

1. You should have installed and started Docker
2. You should have created a directory `mail2dt` beneath your home directory (either by
   just downloading and extracting the ZIP file of this repository,
   or by installing Git, and cloning this repository - into your home folder).


## CONFIGURATION

We are going to show you the least amount of steps that you can take to
configure for you. This entails the following steps:

1. Start the Docker Container (that's where the IMAP Server is running)
2. Configure your existing Mail Client (so, Apple Mail or Outlook)
3. Add the import script to DevonThink's toolbar, and optionally configure
that script if you also want it to immediately file away the newly imported
emails.

### Start the Docker Container

Since above you already went into the `~/mail2dt` directory, within
that directory, you can simply say

	./run.sh

That will install and run the docker image like so:


	mnott[17:10:23]@MatthiasMacBook:~/mail2dt$ ./run.sh
	uid=90(dovecot) gid=101(dovecot) groups=101(dovecot),101(dovecot)
	Jun 12 16:21:30 6a399b7c3af8 syslog.info syslogd started: BusyBox v1.27.2
	Jun 12 16:21:30 6a399b7c3af8 mail.info dovecot: master: Dovecot v2.2.36.4 (baf9232c1) starting up for imap (core dumps disabled)
	Jun 12 16:21:30 6a399b7c3af8 mail.info dovecot: ssl-params: Generating SSL parameters
	Jun 12 16:21:30 6a399b7c3af8 mail.info dovecot: ssl-params: SSL parameters regeneration completed

You might see a lot more stuff since it'll install at the first start.

To stop the container, you just hit `Ctrl+C`. See below on how you can
run that container in the background, without keeping your command line
open. For now, keep it running and configure your Mail Client...


### Configure the Mail Client

If you have just cloned the git repository and do not want to bother
about any configuration, once you have started the docker container
(more on that below: You need to start the docker container first,
before you configure your mail client), all that you do is to
go over to your mail client, tell it that you want to connect
to a new mailserver. As mailserver, you use:

	Incoming Mail Server: 127.0.0.1
	User name: mailuser
	Password: mailpass

For the moment, we assume that we are going to move mails into the
**Inbox** of that new mail server. Further below, I'll explain
what you need to do if you want to have the mails going through
some other folder on that new Mail server. So go ahead, and copy
some Mail into that new mail server's Inbox.


### Configure Devon Think

The rest of this section shows how to modify where this program
is going to run, and how to change the username and password.
But before we do so, we also want to utilize a nifty little
script that I wrote for integration with DevonThink.

You can move the file

	~/mail2dt/devonthink/ArchiveMails.scpt

into the directory

	~/Library/Application Scripts/com.devon-technologies.think3/Toolbar

If you move the
file into the above-mentioned directory, and restart DevonThink, you can
then right-click on the toolbar and chose `Customize Toolbar...`. You
should see that script's name, so probably `ArchiveMails`, towards the
bottom of the screen, just left of the `Search` field. From there, you
can drag the script's icon anywhere on your toolbar.

But before you click on that new button, please wait to understand the
script itself. You can edit the file with Apple's `ScriptEditor` app,
by just double-clicking on the file.

Right at the top of the file, you'll see this:

	-- set ruleList to {"00 - Import Emails", "Rule 1", "Rule 2", "Rule 3"}
	set ruleList to {}

Actually, this script can do a lot more than just importing Mails.
For that, it would be sufficient to copy the mails into the Inbox
of DevonThink. And yes, the script does just that by utilizing
a script that comes with it (see the line `do shell script ...`
further down in the script).


But I thought, let's take it a bit further. At the top, you see,
commented out using `--` at the start of the line, a way how
you can reference a sequence of mail rules to be applied directly
to the mails. The second line defines just an empty list, so that
nothing is really done except for copying the mails into the
Inbox.

Yet if you want to automate further, you can create any number of rules
that you want to have working on your mails, and invoke them right after
importing the mails.

For example, the first rule that I have is `00 - Import Emails`. That
rule is a smart rule that takes all items within the global Inbox of
DevonThink of where the file name ends with `.eml` and moves those
items to another folder (since I have multiple databases, I am
using the Inbox of my current email database). So that way, I am
separating out of my global Inbox all mails from non-mails. The
reason to do so is that for some reason, a DevonThink database's
inbox does not have a representation within a directory, except
for the global inbox.

Next I have a bunch of other rules that file the mails further
into other folders. So for example, I might say, search in
- and I'd use now the location where the mails were put by the
`00 - Import Emails` rule - and move mails with a certain sender
to their own folder.

That `ruleList` is worked through sequentially. The last rule that
I have, and that is of immense use for me, is a rule `Not to Me`:
There I search for all Mails that do not have me on the `From:`
or `To:` headers (and that are not form a list of VIPs), and
move them over to a folder `Not to Me`.

So once you've set all this up - and you don't really need to do
anything if you are happy with first seeing the Mails arrive in
your Inbox - then you are done.


## Use

In daily use, you just would make sure that the Docker container is
running. If it is not, for most email clients that I have tried (Apple
Mail, Outlook), that is not really a problem: If you try, from within
them, to move a mail into the new mail server, they will just wait for
that server to come online again, and only then will the mails arrive
there. And until they are there, you can try the import script within
DevonThink as much as you want, it just will not find any new emails
to import.

So when you have your Docker container running (see below for a way
to run it in the background), then you just copy or move the mails
into the new mail server's inbox, and in DevonThink, you click the
new `ArchiveMail` button. There is a 15 second wait withini that
script, and if the mails don't arrive at the first try, it may just
be that your mail client is a bit lazy when copying the mails over.


## Futher Configuration Options

These options here are really just meant as a more detailed documentation
on how everything hangs together. If you are happy with using the default
configuration used above, you can skip this.

### Directories

#### The Application's Directory

There is not a whole lot to configure. The directory `mail2dt` is
referenced in a small number of places:

* `docker-compose.yaml`
* `devonthink/mail2devonthink.sh`
* `devonthink/ArchiveMails.scpt`

##### `docker-compose.yaml`

`docker-compose.yaml` is the configuration file of the docker image.
It needs to refer to an actual directory. What
we are doing there is to share, with the docker image, two directories
on the computer where docker is running. These directories are, from
the point of view of `mail2dt`,

* `./config`: Contains the configuration for the IMAP server
* `./mail`: Will contain the actual emails

And that is really what is behind the whole idea here: If you
copy a mail into this IMAP server, what happens is that it will
create a file of that mail (containing all attachments) on disk.
And the location where we want him to store that file is not within
the container, but within a location outside of that container, so
that with the script described below, we can move that file from
there into the inbox of DevonThink.


##### `devonthink/mail2devonthink.sh`

This is the script that copies the files from where the IMAP
server within the Docker container has put the email files,
into the inbox of DevonThink.

At the top of that file, you can see

	ROOTDIR=~/mail2dt

You would need to change that directory to something else if you
had installed the git repository somewhere else.


##### `devonthink/ArchiveMails.scpt`

That file you should open with Apple's Script Editor application (it is a
binary file format). It contains a direct reference to the directory `mail2dt`:

	do shell script "~/mail2dt/devonthink/mail2devonthink.sh"

That is so because if otherwise run from within DevonThink, the
file would not find the shell script. Adapt this file if you want
it to pick up the `mail2devonthink.sh` from another location.


#### The IMAP Server

If you want to keep the default user, `mailuser`, and its password,
`mailpass`, you do not need to change anything. That should be fine,
as after all, you are running this server only locally, and only as
a temporary vehicle to transfer mails.

If you want to change these settings, you need to head over to the
`config` directory. Within `dovecot.passwd`, you can replace the
string `mailuser` by a mail user name that you might like (it appears
twice in that file). If you do so, you also need to replace that
same username into the file `devonthink/mail2devonthink.sh`:
At the top, there is a setting

	MAILUSR=mailuser

You would have to change that settings.

Similarly, within `dovecot.passwd`, you could exchange the
string `mailpass` with something else. Of course, if you do
change `mailuser` or `mailpass`, you need to configure your
mail client accordingly.

Also, within the `config` directory, there are two key
files and a generator, `make_keys.sh`
for those. These files are required for the IMAP server to use SSL,
and they are likewise not really relevant content-wise.
The `make_keys.sh` uses `openssl` to generate those files. You
can use that file as a reference and generate your own files,
if you want. the IMAP server just knows about the file names,
and expects them to be in that place.



#### The Mail Transporter

Within the `devonthink` directory, there is a file `mail2devonthink.sh`.
That file is there to take the files from the IMAP server and move them
over to the inbox of DevonThink.

The script tries to be a bit clever with regards to naming the
files within the inbox of DevonThink: The IMAP server names the
files arbitrarily, and if we would just copy those files, with
their original names, into DevonThink, the names shown would
not be readable. Hence what we do here is to use a second
script, `root/usr/local/bin/subject-decoder.pl`, to read each mail's
subject line, and create a filename out of that (since this file
requires some Perl modules, we run it inside the Docker container
where we can ensure we have what we need). And in case
the subject would not be unique, to not overwrite a potentially
existing file in the inbox of DevonThink, we append a counter to
the filename if necessary.

If you look at the header of that file,
you'll see some configuration options:

	ROOTDIR=~/mail2dt
	MAILUSR=mailuser
	DTINBOX=~/Library/Application\ Support/DEVONthink\ 3/Inbox/
	MAILDIR=$ROOTDIR/mail/$MAILUSR/Maildir
	CLEANUP=false
	VERBOSE=true

The `ROOTDIR` and `MAILUSR` we already spoke about. The `DTINBOX`
variable contains the actual location of your DevonThink inbox.
If you have that in another place, change that reference here.

The `MAILDIR` refers to the source directory for the emails;
in other words, to the directory where the IMAP server would
store its mails, and from where the `mail2devonthink.sh`
would take them to transfer them over to the DevonThink inbox.

Since there is a full fledged IMAP server that is
running within the Docker container, you might want to use some
subdirectory of that `MAILDIR` (in other words, a folder within
your IMAP server). If you do so, just create that folder from
within your Mail client, copy some email there, and observe
what's going on within that `MAILDIR` folder. What you are
looking for is the parent directory of the actual directory
where that mail is going to show up (it is going to have
some funny file name). The mail will end up inside some `new`
or `cur` directory beneath the directory which you want to set
as value to the `MAILDIR` variable.

If this is all gibberish to you, then just don't bother changing
any of those settings above...

There is one more thing in that file that you should consider,
whether you understood the previous parts or not. There is that
`CLEANUP` variable at the top. It is set to `false` by default.
If you want to remove the mails from the IMAP server (so that
you don't have to delete them within your Mail client after
transferring them to DevonThink), then you can set this to
`true`. Make sure you have really tested everything well
before you do that. You can always run the script just from
the command line like so:

	./devonthink/mail2devonthink.sh

and if you do so, you will then see what is going on. If you
want to make the script rather not say what it does, you can
later set the `VERBOSE` variable to `false`.




#### The Docker Container

Far above, you've learned to use the

	./run.sh

script to start the Docker container. It will optionally
download what is needed, create the container, and run
it. To get out of it, you just hit `Ctrl+C`.

From a directory structure perspective, there are three
directories that are relevant here.


* The `config` directory is there to configure the password
of the IMAP server.
* The `mail` directory is where the mail files are put by the
IMAP server.
* The `root` directory contains the actual installation of the
IMAP server.

The `root` directory is configured within the `Dockerfile`, and
the `config` and `mail` directories are configured within the
`docker-compose.yaml`.

The `run.sh` starts the Docker container in an interactive
mode, but why not make this even a bit nicer. I'm also
embedding, as part of this repository, a Docker control
script that I've written. It's just called `d`. You can call it
like so:

	./d

It will come up with a menu for you:

	-------------------------------------------
	       D O C K E R      C O N T R O L
	-------------------------------------------

	Compose

	[up]    Up
	[down]  Down

	Containers

	[la]    List    All       Containers
	[ls]    List    Running   Containers

	[start] Start   Container
	[stop]  Stop    Container
	[rm]    Remove  Container
	[rms]   Remove  Stopped Containers

	Images

	[lsi]   List    All       Images
	[lsd]   List    Dangling  Images
	[rmd]   Remove  Dangling  Images
	[rmi]   Remove  Image

	[edit]  Edit    Dockerfile
	[build] Build   Image

	Console

	[con]   Connect to Container

	Enter choice or q to exit:


So if you want to take that docker container up,
you can just type `up` followed by `Enter`.
To take it down, you can just say `down`, followed
by `Enter`.

`ls` will list the running containers:

	Enter choice or q to exit: ls

	Running Containers:

	CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                  NAMES
	8fa24fa71098        mnott/mail          "/run.sh"           34 seconds ago      Up 33 seconds       0.0.0.0:993->993/tcp   	mail2dt_mail_1
	Press [Enter] key to continue...

which you can then also stop like so:

	Enter choice or q to exit: stop

	Running Containers:

	CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS              PORTS                  NAMES
	8fa24fa71098        mnott/mail          "/run.sh"           About a minute ago   Up About a minute   0.0.0.0:993->993/tcp   mail2dt_mail_1
	Enter Container name to stop: [] 8f

	8f

	Press [Enter] key to continue...

Notice how I have used a part of the `CONTAINER ID` to
identify which container I wanted, in this case, stop.
You can also even connect to the command line within
the runnign Container using the `con` command:

	Enter choice or q to exit: con

	Running Containers:

	CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                  NAMES
	8fa24fa71098        mnott/mail          "/run.sh"           3 minutes ago       Up 29 seconds       0.0.0.0:993->993/tcp   mail2dt_mail_1
	Enter Container name to connect to: [8f]

	bash-4.4# ls
	bin     config  dev     etc     home    lib     mail    media   mnt     proc    root    run     run.sh  sbin    srv     sys     tmp     usr     var
	bash-4.4# exit
	exit

	Press [Enter] key to continue...

And finally if you want to delete the container, and the "image" that
it was built out of, you can do first remove the container, and then
its image, with the corresponding menu options.

So this part is really just a very useful addon that you can use
for any Docker containers. Especially the management of containers
and images has been very useful for me, as I am too lazy to try to
remember all the command line options that Docker comes along with.
