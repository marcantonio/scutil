var search_data = {"index":{"searchIndex":["scutil","connectioncache","error","exec","systemconnection","testscutil","testscutilalt","<<()","check_pty_needed?()","clear!()","divert_stdout()","divert_stdout()","each()","exec_command()","exec_command()","exists?()","fetch()","get_connection()","new()","new()","new()","new()","remove()","remove_all()","revert_stdout()","revert_stdout()","scrub_options()","set_options()","setup()","setup()","teardown()","teardown()","test_added_to_cache()","test_added_to_cache()","test_alter_options()","test_clear_connection()","test_exception_raised()","test_exec_command_output()","test_exec_command_output()","test_exec_doesnt_raise_an_exception()","test_exec_doesnt_raise_an_exception()","test_object_initialized()","test_object_is_correct_class()","test_option_force_pty()","test_option_pty_regex()","test_option_verbose_set_and_local_options_take_precedence()","test_pty_not_requested()","test_pty_requested()","test_run_failed_command()","test_run_failed_command()","test_run_successful_command()","test_run_successful_command()","to_s()","to_s()","to_s()","changelog","readme","thanks"],"longSearchIndex":["scutil","scutil::connectioncache","scutil::error","scutil::exec","scutil::systemconnection","testscutil","testscutilalt","scutil::connectioncache#<<()","scutil::check_pty_needed?()","scutil::clear!()","testscutil#divert_stdout()","testscutilalt#divert_stdout()","scutil::connectioncache#each()","scutil::exec_command()","scutil::exec#exec_command()","scutil::connectioncache#exists?()","scutil::connectioncache#fetch()","scutil::systemconnection#get_connection()","scutil::connectioncache::new()","scutil::error::new()","scutil::exec::new()","scutil::systemconnection::new()","scutil::connectioncache#remove()","scutil::connectioncache#remove_all()","testscutil#revert_stdout()","testscutilalt#revert_stdout()","scutil::systemconnection#scrub_options()","scutil::exec#set_options()","testscutil#setup()","testscutilalt#setup()","testscutil#teardown()","testscutilalt#teardown()","testscutil#test_added_to_cache()","testscutilalt#test_added_to_cache()","testscutil#test_alter_options()","testscutil#test_clear_connection()","testscutil#test_exception_raised()","testscutil#test_exec_command_output()","testscutilalt#test_exec_command_output()","testscutil#test_exec_doesnt_raise_an_exception()","testscutilalt#test_exec_doesnt_raise_an_exception()","testscutil#test_object_initialized()","testscutil#test_object_is_correct_class()","testscutil#test_option_force_pty()","testscutil#test_option_pty_regex()","testscutil#test_option_verbose_set_and_local_options_take_precedence()","testscutil#test_pty_not_requested()","testscutil#test_pty_requested()","testscutil#test_run_failed_command()","testscutilalt#test_run_failed_command()","testscutil#test_run_successful_command()","testscutilalt#test_run_successful_command()","scutil::connectioncache#to_s()","scutil::error#to_s()","scutil::systemconnection#to_s()","","",""],"info":[["Scutil","","Scutil.html","",""],["Scutil::ConnectionCache","","Scutil/ConnectionCache.html","","<p>Utiliy class to hold all the connections created, possibly for reuse later.\n"],["Scutil::Error","","Scutil/Error.html","","<p>Exception class for scutil.  The system, error message, and return value of\nthe remote command are stored …\n"],["Scutil::Exec","","Scutil/Exec.html","","<p>Instantiate this class if you wish to use scutil as an object. For example:\n\n<pre>exec = Scutil::Exec.new('severname', ...</pre>\n"],["Scutil::SystemConnection","","Scutil/SystemConnection.html","","<p>Wrapper for each connection to a system.  Capabile of holding a standard\nconnect (@connection) and and …\n"],["TestScutil","","TestScutil.html","",""],["TestScutilAlt","","TestScutilAlt.html","",""],["<<","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-i-3C-3C","(conn)",""],["check_pty_needed?","Scutil","Scutil.html#method-c-check_pty_needed-3F","(cmd, options, hostname)","<p>Should we request a PTY?  Uses custom regex if defined in\n<code>:scutil_pty_regex</code>.\n"],["clear!","Scutil","Scutil.html#method-c-clear-21","(hostname)","<p>Drops all instances of <code>hostname</code> from connection_cache.\n"],["divert_stdout","TestScutil","TestScutil.html#method-i-divert_stdout","()",""],["divert_stdout","TestScutilAlt","TestScutilAlt.html#method-i-divert_stdout","()",""],["each","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-i-each","()","<p>Need each to mixin Enumerable\n"],["exec_command","Scutil","Scutil.html#method-c-exec_command","(hostname, username, cmd, output=nil, options={})","<p>Scutil.exec_command is used to execute a command, specified in\n<em>cmd</em>, on a remote system.  The return value …\n"],["exec_command","Scutil::Exec","Scutil/Exec.html#method-i-exec_command","(cmd, output=nil, options={})","<p>See Scutil.exec_command.  Takes <em>cmd</em> and optionally\n<em>output</em>, and <em>options</em>.  Other arguments specified at …\n"],["exists?","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-i-exists-3F","(hostname)",""],["fetch","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-i-fetch","(hostname)",""],["get_connection","Scutil::SystemConnection","Scutil/SystemConnection.html#method-i-get_connection","(hostname, username, pty_needed=false, options={})","<p>Return a connection for system.  Checks to see if an established connection\nexists.  If not it creates …\n"],["new","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-c-new","()",""],["new","Scutil::Error","Scutil/Error.html#method-c-new","(message=nil, hostname=nil, command_exit_status=-1)",""],["new","Scutil::Exec","Scutil/Exec.html#method-c-new","(hostname, username, options={})",""],["new","Scutil::SystemConnection","Scutil/SystemConnection.html#method-c-new","(hostname, options={})",""],["remove","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-i-remove","(hostname)","<p>Remove all instances of <em>hostname</em>.\n"],["remove_all","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-i-remove_all","()",""],["revert_stdout","TestScutil","TestScutil.html#method-i-revert_stdout","()",""],["revert_stdout","TestScutilAlt","TestScutilAlt.html#method-i-revert_stdout","()",""],["scrub_options","Scutil::SystemConnection","Scutil/SystemConnection.html#method-i-scrub_options","(options)","<p>Remove scutil specific options.  The rest go to Net::SSH.\n"],["set_options","Scutil::Exec","Scutil/Exec.html#method-i-set_options","(options={})",""],["setup","TestScutil","TestScutil.html#method-i-setup","()",""],["setup","TestScutilAlt","TestScutilAlt.html#method-i-setup","()",""],["teardown","TestScutil","TestScutil.html#method-i-teardown","()",""],["teardown","TestScutilAlt","TestScutilAlt.html#method-i-teardown","()",""],["test_added_to_cache","TestScutil","TestScutil.html#method-i-test_added_to_cache","()",""],["test_added_to_cache","TestScutilAlt","TestScutilAlt.html#method-i-test_added_to_cache","()",""],["test_alter_options","TestScutil","TestScutil.html#method-i-test_alter_options","()",""],["test_clear_connection","TestScutil","TestScutil.html#method-i-test_clear_connection","()",""],["test_exception_raised","TestScutil","TestScutil.html#method-i-test_exception_raised","()",""],["test_exec_command_output","TestScutil","TestScutil.html#method-i-test_exec_command_output","()",""],["test_exec_command_output","TestScutilAlt","TestScutilAlt.html#method-i-test_exec_command_output","()",""],["test_exec_doesnt_raise_an_exception","TestScutil","TestScutil.html#method-i-test_exec_doesnt_raise_an_exception","()",""],["test_exec_doesnt_raise_an_exception","TestScutilAlt","TestScutilAlt.html#method-i-test_exec_doesnt_raise_an_exception","()",""],["test_object_initialized","TestScutil","TestScutil.html#method-i-test_object_initialized","()",""],["test_object_is_correct_class","TestScutil","TestScutil.html#method-i-test_object_is_correct_class","()",""],["test_option_force_pty","TestScutil","TestScutil.html#method-i-test_option_force_pty","()",""],["test_option_pty_regex","TestScutil","TestScutil.html#method-i-test_option_pty_regex","()",""],["test_option_verbose_set_and_local_options_take_precedence","TestScutil","TestScutil.html#method-i-test_option_verbose_set_and_local_options_take_precedence","()",""],["test_pty_not_requested","TestScutil","TestScutil.html#method-i-test_pty_not_requested","()",""],["test_pty_requested","TestScutil","TestScutil.html#method-i-test_pty_requested","()",""],["test_run_failed_command","TestScutil","TestScutil.html#method-i-test_run_failed_command","()",""],["test_run_failed_command","TestScutilAlt","TestScutilAlt.html#method-i-test_run_failed_command","()",""],["test_run_successful_command","TestScutil","TestScutil.html#method-i-test_run_successful_command","()",""],["test_run_successful_command","TestScutilAlt","TestScutilAlt.html#method-i-test_run_successful_command","()",""],["to_s","Scutil::ConnectionCache","Scutil/ConnectionCache.html#method-i-to_s","()",""],["to_s","Scutil::Error","Scutil/Error.html#method-i-to_s","()",""],["to_s","Scutil::SystemConnection","Scutil/SystemConnection.html#method-i-to_s","()",""],["CHANGELOG","","CHANGELOG_rdoc.html","","<p>Changelog\n<p>0.3.0 | 2011-10-11\n<p>Added set_options method to instance.\n"],["README","","README_rdoc.html","","<p>scutil\n<p>Description:\n<p>Scutil <em>(pronounced “scuttle”)</em> is a small Ruby library that makes\nusing Net::SSH …\n"],["THANKS","","THANKS_rdoc.html","","<p>Thanks\n<p>Kevin McAllister &lt;kevin@mcallister.ws&gt; for the name and much feedback\nand discussion.\n<p>Jamis …\n"]]}}