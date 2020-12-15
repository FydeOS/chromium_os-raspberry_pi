#!/usr/bin/env python2
# -*- coding: utf-8 -*-
#
# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Ensures that V8's embedded blob is marked as hot.

This is important for performance, as we ensure that code marked as hot ends up
in hugepages. If this isn't the case, there's a good chance that these builtins
may 'accidentally' end up in hugepages, or won't end up in hugepages at all.
"""

# As noted in Chrome's ebuild, this test is a temporary hack until we ship
# orderfiles. Those will guarantee the ordering of this code/etc, so we don't
# need a special hot section anymore.

from __future__ import print_function

import argparse
import subprocess
import sys


def _parse_text_hot_bounds(chrome_binary):
    # Grep for the .text.hot section. There should be exactly one of these.
    # Section output looks like:
    # [18] .text.hot  PROGBITS   00b2d000 b2d000 5cb9b8 00  AX  0   0 32
    # With offset being the fourth field, and size being the sixth field.
    readelf = subprocess.check_output(
        ['llvm-readelf', '--sections', '--wide', chrome_binary]).splitlines()

    text_hot = [line.strip() for line in readelf if '.text.hot' in line]
    if len(text_hot) != 1:
        raise ValueError(
            'Expected exactly one .text.hot section; got: %s' % text_hot)

    hot_line = text_hot[0]
    fields = hot_line.split()
    offset, size = fields[3], fields[5]
    return int(offset, 16), int(size, 16)


def _parse_builtins_locations(chrome_binary):
    # We have to parse lines like:
    #    Num:    Value  Size Type    Bind   Vis      Ndx Name
    # 470796: 00d21560     0 FUNC    LOCAL  DEFAULT   18 Builtins_Abort
    #
    # We can rely on FUNC, LOCAL, and DEFAULT being consistent for all
    # `Builtins_`.
    cmd = subprocess.Popen(['llvm-readelf', '--symbols', '--wide', chrome_binary],
                           stdout=subprocess.PIPE)

    keys = ['FUNC', 'LOCAL', 'DEFAULT']
    ok = True
    try:
        for line in cmd.stdout:
            fields = line.split()
            if not fields:
                continue

            symbol_name = fields[-1]
            if not symbol_name.startswith('Builtins_'):
                continue

            if any(key not in fields for key in keys):
                continue

            location = int(fields[1], 16)
            yield location, symbol_name
    except:
        ok = False
        cmd.kill()
        raise
    finally:
        exit_code = cmd.wait()
        if ok and exit_code:
            raise subprocess.CalledProcessError(exit_code, cmd.args)


def _err(x):
    print(x, file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('chrome', help='Path to an unstripped chrome binary.')
    args = parser.parse_args()

    chrome_binary = args.chrome

    hot_begin, hot_size = _parse_text_hot_bounds(chrome_binary)
    hot_end = hot_begin + hot_size

    out_of_bounds = []
    num_found = 0
    for location, symbol_name in _parse_builtins_locations(chrome_binary):
        num_found += 1
        if location >= hot_end or location < hot_begin:
            out_of_bounds.append((location, symbol_name))

    if not num_found:
        _err("No `Builtins_` found. Is the given chrome stripped?")
        return 1

    if not out_of_bounds:
        print('%d `Builtins_` functions in .text.hot.' % num_found)
        return 0

    out_of_bounds.sort()
    _err('%d/%d builtins didn\'t land in .text.hot.' % (len(out_of_bounds),
                                                        num_found))
    _err('.text.hot begin: %#x' % hot_begin)
    _err('.text.hot end: %#x' % hot_end)

    pretty_out_of_bounds = ('%#x: %s' % (offset, name)
                            for offset, name in out_of_bounds)
    _err('Builtins:\n\t' + '\n\t'.join(pretty_out_of_bounds))
    return 1


if __name__ == '__main__':
    sys.exit(main())
