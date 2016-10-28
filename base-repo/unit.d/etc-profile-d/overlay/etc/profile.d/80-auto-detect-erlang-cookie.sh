if [ -s "${ERLANG_COOKIE_SRC:=/volumes/secrets/.erlang.cookie}" ] ||
    [ -n "$ERLANG_COOKIE" ]; then
        erlang-cookie-tool "auto-detect"
fi

