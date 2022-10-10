import os
import logging
from . import (
    log,
    get_arg_parser,
    add_args,
    verify_args,
)
from .upload import upload_ui, upload_test


def main() -> None:
    parser = get_arg_parser()
    add_args(parser)
    args = parser.parse_args()
    try:
        verify_args(args)
    except ValueError as e:
        parser.error(e)

    if args.verbose:
        log.setLevel(logging.DEBUG)

    if args.test_build:
        upload_test(args)
    else:
        upload_ui(args)


if __name__ == "__main__":
    main()
