import os
import logging
from . import (
    log,
    get_arg_parser,
    add_args,
    upload_ui,
    verify_args,
)


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

    upload_ui(args)


if __name__ == "__main__":
    main()
