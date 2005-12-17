#: PerlMaple.t
#: 2005-11-14 2005-12-17

use strict;
use warnings;

use Test::More tests => 31;
BEGIN { use_ok('PerlMaple') }

my $maple = PerlMaple->new;
ok $maple;
ok !defined $maple->error;
isa_ok($maple, 'PerlMaple');

ok $maple->PrintError;
ok not $maple->RaiseError;

my $ans = $maple->eval_cmd('eval(int(2*x^3,x), x=2);');
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval('eval(int(2*x^3,x), x=2)');
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval_cmd("eval(int(2*x^3,x), x=2);  \n \n\r");
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval_cmd("eval(int(2*x^3,x), x=2");
ok !defined $ans;
ok $maple->error;
like $maple->error, qr/unexpected end of/i;

$maple = PerlMaple->new(
  PrintError => 0,
  RaiseError => 1,
);
ok $maple;
isa_ok $maple, 'PerlMaple';

ok not $maple->PrintError;
ok $maple->RaiseError;

$maple->RaiseError(undef);
ok not $maple->PrintError;
ok not $maple->RaiseError;

$ans = $maple->eval_cmd("3+1");
ok !defined $ans;
ok $maple->error;
like $maple->error, qr/unexpected end of/i;

$ans = $maple->eval('int(2*x^3,x)', 'x=2');
is $ans, 8;
ok !defined $maple->error;

my $exp = $maple->int('2*x^3', 'x');
$ans = $maple->eval($exp, 'x=2');
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval_cmd(<<'.');
lc := proc( s, u, t, v )
         description "form a linear combination of the arguments";
         s * u + t * v
end proc;
.

like $ans, qr/proc.*description/;
ok !defined $maple->error;

$maple->eval('3+2');
is $maple->eval_cmd('3+1:'), '';
