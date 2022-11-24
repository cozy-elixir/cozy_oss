defmodule CozyOSS.ApiRequestTest do
  use ExUnit.Case
  alias CozyOSS.ApiRequest

  describe "important underlying functions works as expected, such as" do
    test "build_string_to_sign_for_header_signature/1" do
      request = %ApiRequest{
        scheme: :https,
        host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
        port: 443,
        method: "PUT",
        path: "/nelson",
        query: %{},
        headers: %{
          "content-md5" => "eB5eJF1ptWaXm4bijSPyxw==",
          "content-type" => "text/html",
          "date" => "Thu, 17 Nov 2005 18:49:58 GMT",
          "x-oss-meta-author" => "foo@example.com",
          "x-oss-meta-magic" => "abracadabra"
        },
        body: nil,
        private: %{
          bucket: "examplebucket",
          object: "nelson",
          sub_resources: %{}
        }
      }

      assert ApiRequest.build_string_to_sign_for_header_signature(request) ==
               "PUT\neB5eJF1ptWaXm4bijSPyxw==\ntext/html\nThu, 17 Nov 2005 18:49:58 GMT\nx-oss-meta-author:foo@example.com\nx-oss-meta-magic:abracadabra\n/examplebucket/nelson"
    end

    test "build_string_to_sign_for_url_signature/1" do
      request = %ApiRequest{
        scheme: :https,
        host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
        port: 443,
        method: "PUT",
        path: "/nelson",
        query: %{},
        headers: %{
          "content-md5" => "eB5eJF1ptWaXm4bijSPyxw==",
          "content-type" => "text/html",
          "date" => "Thu, 17 Nov 2005 18:49:58 GMT",
          "x-oss-meta-author" => "foo@example.com",
          "x-oss-meta-magic" => "abracadabra"
        },
        body: nil,
        private: %{
          bucket: "examplebucket",
          object: "nelson",
          sub_resources: %{}
        }
      }

      assert ApiRequest.build_string_to_sign_for_url_signature(request, 1800) ==
               "PUT\neB5eJF1ptWaXm4bijSPyxw==\ntext/html\n1800\nx-oss-meta-author:foo@example.com\nx-oss-meta-magic:abracadabra\n/examplebucket/nelson"
    end

    test "canonicalize_oss_headers/1" do
      assert ApiRequest.canonicalize_oss_headers(%{}) == ""

      assert ApiRequest.canonicalize_oss_headers(%{
               "x-oss-meta-a" => "a",
               "x-oss-meta-c" => "c",
               "x-oss-meta-b" => "b"
             }) == "x-oss-meta-a:a\nx-oss-meta-b:b\nx-oss-meta-c:c"

      assert ApiRequest.canonicalize_oss_headers(%{
               "x-oss-meta-a" => nil,
               "x-oss-meta-c" => "c"
             }) == "x-oss-meta-a\nx-oss-meta-c:c"
    end

    test "canonicalize_resource/3" do
      assert ApiRequest.canonicalize_resource("example-bucket", "example-object", %{
               uploadId: 2,
               acl: nil
             }) == "/example-bucket/example-object?acl&uploadId=2"

      assert ApiRequest.canonicalize_resource("example-bucket", nil, %{
               uploadId: 2,
               acl: nil
             }) == "/example-bucket/?acl&uploadId=2"

      assert ApiRequest.canonicalize_resource(nil, nil, %{
               uploadId: 2,
               acl: nil
             }) == "/?acl&uploadId=2"

      assert ApiRequest.canonicalize_resource("example-bucket", "example-object", %{}) ==
               "/example-bucket/example-object"
    end
  end
end
