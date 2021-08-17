echo
echo '#### SUMMARY ####'
grep TEST_LOG $GRABDISH_LOG/main-test.log

echo
echo '#### FAILURES ####'
grep TEST_LOG_FAILED $GRABDISH_LOG/main-test.log