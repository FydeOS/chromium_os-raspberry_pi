#!/usr/bin/env python3
# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Ensures that Chrome has the ordering we expect.

Chrome is ordered by an orderfile. This orderfile needs to do a few things:
  - Ensure that markers are at each end of the ordered code, so Chrome can move
    that to hugepages.
  - Ensure that V8's builtins are somewhere between these markers.
  - Ensure that the markers are in the correct order, since Chrome has strict
    expectations about their relative ordering.

This is important for performance, as we ensure that code marked as hot ends up
in hugepages.
"""

from __future__ import print_function

import argparse
import subprocess
import sys
from typing import List, Tuple


def _parse_text_section_bounds(chrome_binary: str) -> Tuple[int, int]:
    """Find out the boundary of text section from readelf.

    Section output looks like:
        [Nr] Name  Type     Address  Off     Size    ES Flg Lk Inf Al
        [16] .text PROGBITS 01070000 1070000 9f82cf6 00 AX  0  0   64

    With offset being the fourth field, and size being the sixth field.

    Args:
        chrome_binary: Path to unstripped Chrome binary.

    Returns:
        (offset, size): offset and size of text section.
    """
    readelf = subprocess.check_output(
        ['llvm-readelf', '--sections', '--wide', chrome_binary]).splitlines()
    text = [x.strip() for x in readelf if b'.text' in x]
    if len(text) != 1:
        raise ValueError(f'Expected exactly one .text section; got: {text}')

    text_line = text[0]
    fields = text_line.split()
    offset, size = fields[3], fields[5]
    return int(offset, 16), int(size, 16)


def _parse_orderfile_marker_bounds(chrome_binary: str) -> Tuple[int, int]:
    """Find out the address of markers from orderfile in readelf.

    We have to parse lines like:
        Num:    Value            Size Type Bind  Vis     Ndx Name
        403015: 0000000001070000 5    FUNC LOCAL DEFAULT 16  chrome_begin_[...]
        403016: 00000000020e3dc0 5    FUNC LOCAL DEFAULT 16  chrome_end_[...]

    Addresses are at the second field.

    Args:
        chrome_binary: Path to unstripped Chrome binary.

    Returns:
        (start, end): addresses of chrome_begin_ordered_code and
        chrome_end_ordered_code.
    """
    readelf = subprocess.check_output(
        ['readelf', '--symbols', '--wide', chrome_binary]).splitlines()

    marker_start = [
        x.strip() for x in readelf if b'chrome_begin_ordered_code' in x
    ]
    if len(marker_start) != 1:
        raise ValueError('Expect exactly one chrome_begin_ordered_code marker')
    marker_end = [
        x.strip() for x in readelf if b'chrome_end_ordered_code' in x
    ]
    if len(marker_end) != 1:
        raise ValueError('Expect exactly one chrome_end_ordered_code marker')

    parse_size = lambda x: int(x[0].split()[1], 16)
    return parse_size(marker_start), parse_size(marker_end)


def _parse_builtins_locations(chrome_binary: str) -> List[Tuple[int, str]]:
    """Find out all the builtin functions and their locations

    We have to parse lines like:
           Num:    Value  Size Type    Bind   Vis      Ndx Name
        470796: 00d21560     0 FUNC    LOCAL  DEFAULT   18 Builtins_Abort

    We can rely on FUNC, LOCAL, and DEFAULT being consistent for all
    `Builtins_`.

    Args:
        chrome_binary: Path to unstripped Chrome binary.

    Returns:
        List of (location, symbol_name): a list of tuples of the address and
        names of builtin functions
    """
    cmd = subprocess.Popen(['readelf', '--symbols', '--wide', chrome_binary],
                           stdout=subprocess.PIPE)

    keys = (b'FUNC', b'LOCAL', b'DEFAULT')
    ok = True
    try:
        for line in cmd.stdout:
            fields = line.split()
            if not fields:
                continue

            symbol_name = fields[-1]
            if not symbol_name.startswith(b'Builtins_'):
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
    """Print error message."""
    print(f'{__file__}: error: {x}', file=sys.stderr)


def main(argv):
    """Main function."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('chrome', help='Path to an unstripped chrome binary.')
    opts = parser.parse_args(argv)

    chrome_binary = opts.chrome

    text_start, text_end = _parse_text_section_bounds(chrome_binary)
    marker_start, marker_end = _parse_orderfile_marker_bounds(chrome_binary)

    if marker_start < text_start or marker_end >= text_end:
        _err('Markers landed outside of text section')
        return 1

    if marker_start >= marker_end:
        _err('Markers are not ordered correctly')
        return 1

    out_of_bounds = []
    num_found = 0
    for location, symbol_name in _parse_builtins_locations(chrome_binary):
        num_found += 1
        if location >= marker_end or location < marker_start:
            out_of_bounds.append((location, symbol_name))

    if not num_found:
        _err('No `Builtins_` found. Is the given chrome stripped?')
        return 1

    if not out_of_bounds:
        print(f'[PASS] {num_found} `Builtins_` functions are placed between '
              'the markers')
        return 0

    out_of_bounds.sort()
    _err(f"{len(out_of_bounds)}/{num_found} builtins didn't land in "
         'between the markers')
    _err(f'chrome_begin_ordered_code: {marker_start:#x}')
    _err(f'chrome_end_ordered_code: {marker_end:#x}')

    pretty_out_of_bounds = (f'{offset:#x}: {name}'
                            for offset, name in out_of_bounds)
    _err('Builtins:\n\t' + '\n\t'.join(pretty_out_of_bounds))
    return 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
