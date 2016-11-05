require 'honeybadger/ruby'

agent = Honeybadger::Agent.new(backend: 'debug', debug: true, api_key: 'asdf', logger: Logger.new(STDOUT))

agent.notify(error_class: 'CustomHoneybadgerException', error_message: 'Test message')

agent.flush

raise 'This should not be reported.'
