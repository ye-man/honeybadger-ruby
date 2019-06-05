require 'honeybadger/plugins/breadcrumbs'
require 'honeybadger/config'

describe "Breadcrumbs Plugin" do
  let(:config) { Honeybadger::Config.new(logger: NULL_LOGGER, debug: true) }
  let(:active_support) { double("ActiveSupport::Notifications") }

  before do
    Honeybadger::Plugin.instances[:breadcrumbs].reset!
    stub_const("ActiveSupport::Notifications", active_support)
  end

  describe Honeybadger::Plugins::RailsBreadcrumbs do
    describe ".subscribe_to_notification" do
      it "registers with activesupport and delgates to send_breadcrumb_notification" do
        name = "a.notification"
        config = { foo: "bar" }
        data = {a: :b}
        expect(described_class).to receive(:send_breadcrumb_notification).with(name, 10, config, data)
        expect(active_support).to receive(:subscribe).with(name) do |&block|
          block.call("noop", 10, 20, "noop", data)
        end

        described_class.subscribe_to_notification(name, config)
      end
    end

    describe ".send_breadcrumb_notification" do
      it "adds a breadcrumb with overridden config settings" do
        data = {cars: "trucks"}
        config = {message: "config message", category: :test}

        expect(Honeybadger).to receive(:add_breadcrumb).with("config message", {category: :test, metadata: data.merge({duration: 99})})
        described_class.send_breadcrumb_notification("message", 99, config, data)
      end

      it "adds a breadcrumb with defaults" do
        expect(Honeybadger).to receive(:add_breadcrumb).with("message", {category: :custom, metadata: {duration: 100}})
        described_class.send_breadcrumb_notification("message", 100, config, {})
      end

      describe ":exclude_when" do
        it "excludes events if proc returns true" do
          data = {}
          config = {
            exclude_when: lambda do |d|
              expect(d).to eq(data)
              true
            end
          }

          expect(Honeybadger).to_not receive(:add_breadcrumb)
          described_class.send_breadcrumb_notification("name", 10, config, data)
        end

        it "includes event if proc returns true" do
          config = { exclude_when: ->(_){ false } }
          expect(Honeybadger).to receive(:add_breadcrumb)
          described_class.send_breadcrumb_notification("name", 33, config, {})
        end
      end

      describe ":select_keys" do
        it "can filter metadata" do
          data = {a: :b, c: :d}
          selected_data = {a: :b}
          config = { select_keys: [:a] }

          expect(Honeybadger).to receive(:add_breadcrumb).with(anything, hash_including(metadata: selected_data))
          described_class.send_breadcrumb_notification("_", 0, config, data)
        end
      end

      describe ":transform" do
        it "transforms data payload" do
          data     = {old: "data"}
          new_data = {new: "data"}
          config = {
            transform: lambda do |d|
              expect(d).to eq(data)
              new_data
            end
          }
          expect(Honeybadger).to receive(:add_breadcrumb).with(anything, hash_including(metadata: new_data))

          described_class.send_breadcrumb_notification("name", 33, config, data)
        end
      end

    end
  end
end
