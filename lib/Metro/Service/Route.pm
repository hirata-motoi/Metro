package Metro::Service::Route;
use strict;
use warnings;
use utf8;
use YAML;

use parent qw/Metro::Service::Base/;

sub get_shortest_route {
    my ($self, $nodes, $from, $to) = @_;

    # 最短経路リスト
    my $roots = {};

    # スタートノード
    my $done_node = (grep { $_->{id} == $from } @$nodes)[0];

    while (1) {
        my $next_node = undef;

        # 次に伸びているノードの中で最小のものを調査
        for my $edge (sort keys %{$done_node->{edges}}) {
            my $cost = $done_node->{edges}{$edge};

            my $node_by_edge = (grep { $_->{id} == $edge } @$nodes)[0];

            # 既に通った道か？
            if ($node_by_edge->{done}) {
                next;
            }

            # 距離計算
            if (!$roots->{$edge} || $done_node->{distance} + $cost < $roots->{$edge}) {
                $node_by_edge->{distance} = $done_node->{distance} + $cost;
                $node_by_edge->{from}     = $done_node->{id};
      
                # 最短経路登録
                $roots->{$edge} = $node_by_edge->{distance}
            }
        }

        my @tmp;
        for (@$nodes) {
            if (!$_->{done} && $_->{distance}) {
                push @tmp, $_;
            }
        }
        my @sorted_not_searched = sort{ $a->{distance} <=> $b->{distance} } @tmp;
        #my @sorted_not_searched = sort{ $a->{distance} <=> $b->{distance} } grep { !$_->{done} && $_->{distance} } @$nodes;
        $next_node = $sorted_not_searched[0];
        # 次のノードが決まらなかった場合
        if (!$next_node) {
            last;
        }
  
        # 既に通った道として登録
        $next_node->{done} = 1;
  
        $done_node = $next_node;
    }

    # 経路を調べる
    my @path = ();
    my $goal = $to;
    push @path, $goal;
    my $nt = (grep { $_->{id} == $goal } @$nodes)[0]->{distance};
    while (1) {
        my $node = (grep { $_->{id} == $goal } @$nodes)[0];
        $goal = $node->{from};
        push @path, $goal;

        if (!$goal) {
            die( sprintf "died in Route.pm %s", Dump [grep { $_->{from} } @$nodes]);
        }

        if ($goal == $from) {
            last;
        }
    }
    return (\@path, $nt);
}

1;

