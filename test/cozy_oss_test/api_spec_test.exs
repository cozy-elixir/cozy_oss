defmodule CozyOSS.ApiSpecTest do
  use ExUnit.Case
  alias CozyOSS.ApiSpec

  describe "build!/1" do
    test "creates an %ApiSpec{} struct" do
      assert %ApiSpec{method: _, path: _, query: _, headers: _, body: _} =
               ApiSpec.build!(%{
                 method: "GET",
                 path: "/"
               })
    end

    test "raises ArgumentError when required keys are missing" do
      assert_raise ArgumentError,
                   "key :method, :path are required in a spec",
                   fn ->
                     ApiSpec.build!(%{})
                   end
    end
  end
end
