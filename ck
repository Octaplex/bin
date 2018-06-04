#!/usr/bin/python3
"""
A simple program correctness checker.
"""

from argparse import ArgumentParser
from glob import glob
from os import path
from sys import stdout, stderr
from subprocess import run, PIPE
from crayons import red, green, yellow
from difflib import context_diff

pass_msg = green('PASS', bold=True)
fail_msg = red('FAIL', bold=True)
err_msg = red('ERROR', bold=True)

error = red('error') + ': '
warning = yellow('warning') + ': '

input_suffix = 'in'
output_suffix = 'out'

def die(why, code=1):
    """
    Print an error message to stderr and exit.
    """
    print(error + why, file=stderr)
    exit(code)

def align(text, width):
    """
    Right-align a piece of text to a given width.
    """
    l = len(text)
    if l >= width:
        return text[:width]
    else:
        return (' ' * (width - l)) + text

def print_diff(output, correct, fromfile='output', tofile='correct'):
    """
    Print a context diff of the given sequences.
    """
    stdout.writelines(context_diff(output, correct, fromfile=fromfile,
        tofile=tofile))

parser = ArgumentParser()
parser.add_argument('-r', '--check-return', action='store_true',
        help='Check the return code of each test')
parser.add_argument('-c', '--target-code', type=int, default=0,
        help='The return code to check for')
parser.add_argument('-D', '--diff', action='store_true',
        help='Output a diff for all tests that fail')
parser.add_argument('-d', '--directory', default='test',
        help='The directory to look for tests in')
parser.add_argument('-v', '--verbose', action='store_true',
        help='Print extra information')
parser.add_argument('prog', help='The program to test')
parser.add_argument('test', help='The test(s) to run (default: all tests)', nargs='*')

args = parser.parse_args()
if not path.exists(args.directory):
    die('no such directory: ' + args.directory)

if not path.isfile(args.prog):
    die('no such program: ' + args.prog)

if len(args.test) == 0:
    input_fns = sorted(glob(path.join(args.directory, '*.' + input_suffix)))
else:
    input_fns = sorted(
            path.join(args.directory, test + '.' + input_suffix)
            for test in args.test
            )

    for input_fn in input_fns:
        if not path.isfile(input_fn):
            die('no such test: ' + input_fn)

extra_len = len(args.directory) + len(input_suffix) + 2
test_width = max(4, max(len(input_fn) - extra_len for input_fn in input_fns))

if len(input_fns) == 0:
    print('No tests to process')
    exit(0)

sep = ('-' * test_width) + ' ------'
print(sep)
print(align('Test', test_width) + ' Result')

for input_fn in input_fns:
    root, _ = path.splitext(input_fn)
    output_fn = root + '.' + output_suffix

    name = path.basename(root)
    if not path.exists(output_fn):
        if args.verbose:
            print(warning + 'no output file for input ' + name)

        continue

    with open(output_fn) as output_f:
        correct_stdout = output_f.read()

    with open(input_fn) as input_f:
        result = run(args.prog, stdin=input_f, stdout=PIPE, check=False,
                encoding='utf-8')

    if args.check_return and result.returncode != args.target_code:
        msg = err_msg
    elif result.stdout == correct_stdout:
        msg = pass_msg
    else:
        msg = fail_msg

    print(align(name, test_width) + ' ' + msg)
    if args.diff and msg == fail_msg:
        print_diff(result.stdout, correct_stdout)

print(sep)
