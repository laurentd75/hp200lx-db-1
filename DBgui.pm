#!/usr/local/bin/perl
# FILE %gg/perl/HP200LX/DBgui.pm
#
# Graphical Userinterface for HP 200 LX DBs implemented in Tk
#
# T2D:
# + save complete DB file
# + note view and (configurable) external editor for that biest
# + alternate views:
#   + form and listing based
#   + definition and extrnal storage
#
# T2D strategy:
# + DB object should be independent of HP200 specifics
#
# written:       1998-03-01
# latest update: 1998-06-28 11:17:04
#

package HP200LX::DBgui;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;

$VERSION = '0.03';
@ISA= qw(Exporter);
@EXPORT_OK= qw(browse_db);

use Tk;
use HP200LX::DBcard;
use HP200LX::DBlist;

# ----------------------------------------------------------------------------
sub new
{
  my $class= shift;
  my $db= shift;
  my $title= shift;

  my $bbar= 1;  # show button bar

  my $top= MainWindow->new ();
  $top->title ($title);

  my $mb= $top->Frame (relief => 'raised', width => 40);
  $mb->pack (side => 'top', fill => 'x');

  my $mb_f= $mb->Menubutton (text => 'File', relief => 'raised')
               ->pack (side => 'left', padx => 2, fill => 'x');
  $mb_f->command (label => 'Save', command => sub {$db->saveDB ('test.out');});
  $mb_f->command (label => 'Exit', command => sub {exit});

  my $mb_v= $mb->Menubutton (text => 'Views', relief => 'raised')
               ->pack (side => 'left', padx => 2, fill => 'x');

  my $obj=
  {
    db => $db,
    top => $top,
    title => $title,
    cards => [],
    lists => [],        # indexed by view point number
  };
  bless $obj, $class;

  my $vpt;
  my $i= 0;
  foreach $vpt (@{$db->{viewptdef}})
  {
    my $c= eval ("sub { \$obj->open_list ($i); }");
    $mb_v->command (label => "$i: $vpt->{name}", command => $c);
    $i++;
  }

  my $arg;
  my %first= (top => $top);

  if ($bbar)
  {
    # $top->pack ();
    %first= ();
  }

  while (defined ($arg= shift (@_)))
  {
    print "arg= $arg\n";
    if ($arg eq 'card')
    {
      $obj->open_card (%first);
      %first= ();
    }
    elsif ($arg eq 'list')
    {
      my $view= shift (@_);
      $obj->open_list ($view, %first);
      %first= ();
    }
  }

  $obj->open_list (0, %first) if (defined ($first{top}));
}

# ----------------------------------------------------------------------------
# open a list view with a given number
# NOTE: should it be possible to open more than one wigets with
# the same view point?
sub open_list
{
  my $DBgui= shift;
  my $view= shift;

  my $list;
  # print ">>> open_list view=$view\n";
  if (defined ($list= $DBgui->{lists}->[$view]))
  {
    $list->{top}->raise ();
    $list->{top}->deiconify ();
    return;
  }

  my $title= $DBgui->{title} . ' '. $view;
  # print ">>> title= $title\n";
  my $list= new HP200LX::DBlist ($DBgui, $view, $title, @_);

  $DBgui->{lists}->[$view]= $list;
}

# ----------------------------------------------------------------------------
sub open_card
{
  my $DBgui= shift;

  my $title= $DBgui->{title} . ' card';
  my $card= new HP200LX::DBcard ($DBgui->{db}, $title, @_);
  push (@{$DBgui->{cards}}, $card);

  $DBgui->{active_card}= $card;
}

# ----------------------------------------------------------------------------
sub show_card
{
  my $DBgui= shift;
  my $db_idx= shift;

  my $active_card= $DBgui->{active_card};

  if ($active_card)
  {
    $active_card->show_record ($db_idx, 0);
  }
  else
  {
    $active_card= $DBgui->open_card ('index' => $db_idx);
    $DBgui->set_active ($active_card);
    # T2D ?: show active card
  }
}

# ----------------------------------------------------------------------------
sub browse_db
{
  MainLoop ();
}

# ----------------------------------------------------------------------------
1;
