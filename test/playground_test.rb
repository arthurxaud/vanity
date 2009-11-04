require "test/test_helper"

class PlaygroundTest < MiniTest::Spec
  it "has one global instance" do
    assert instance = Vanity.playground
    assert_equal instance, Vanity.playground
  end

  it "has identity value by default" do
    assert identity = Vanity.identity
    assert_equal identity, Vanity.identity
    assert_match /^[a-f0-9]{32}$/, identity
  end

  it "can accept external identity" do
    Vanity.identity = 678
    assert_equal 678, Vanity.identity
  end

  it "use vanity-{major} as default namespace" do
    assert namespace, Vanity.playground.namespace
  end

  it "fails if it cannot load named experiment from file" do
    assert_raises MissingSourceFile do
      experiment("Green button")
    end
  end

  it "loads named experiment from experiments directory" do
    Vanity.playground.expects(:require).with("experiments/green_button")
    begin
      experiment("Green button")
    rescue LoadError=>ex
    end
  end

  it "complains if experiment not defined in expected filed" do
    Vanity.playground.expects(:require).with("experiments/green_button")
    assert_raises LoadError do
      experiment("Green button")
    end
  end

  it "returns experiment defined in file" do
    playground = class << Vanity.playground ; self ; end
    playground.send :define_method, :require do |file|
      Vanity.playground.define "Green Button" do
        true_false
      end
    end
    assert_equal "green_button", experiment("Green button").name
  end

  it "can define and access experiment using symbol" do
    assert green = experiment("Green Button") { true_false }
    assert_equal green, experiment(:green_button)
    assert red = experiment(:red_button) { true_false }
    assert_equal red, experiment("Red Button")
  end

  it "detect and fail when defining the same experiment twice" do
    experiment "Green Button" do
      true_false
    end
    assert_raises RuntimeError do
      experiment :green_button do
        true_false
      end
    end
  end

  it "evalutes definition block when creating experiment" do
    experiment :green_button do
      true_false
      expects(:xmts).returns("x")
    end
    assert_equal "x", experiment(:green_button).xmts
  end

  it "saves experiments after defining it" do
    experiment :green_button do
      true_false
      expects(:save)
    end
  end

  it "loads experiment if one already exists" do
    experiment :green_button do
      true_false
      @xmts = "x"
    end
    Vanity.instance_variable_set :@playground, Vanity::Playground.new
    experiment :green_button do
      expects(:xmts).returns(@xmts)
    end
    assert_equal "x", experiment(:green_button).xmts
  end

  it "uses playground namespace in experiment" do
    experiment :green_button do
      true_false
    end
    assert_equal "#{namespace}:experiments:green_button", experiment(:green_button).send(:key)
    assert_equal "#{namespace}:experiments:green_button:participants", experiment(:green_button).send(:key, "participants")
  end

  after do
    nuke_playground
  end
end
