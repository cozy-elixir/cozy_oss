# CozyOSS

> SDK builder for RESTful API of Aliyun OSS / Alibaba Cloud OSS.

This package is an SDK builder.

It provides utilities to reduce the cost of creating an SDK, such as:

- building request
- signing request
- ...

## Installation

Add `cozy_oss` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_oss, "~> 0.1.0"}
  ]
end
```

## Usage

Read the example code in this [test](https://github.com/cozy-elixir/cozy_oss/tree/master/test/example_sdk_test.exs).

For more information, see the [documentation](https://hexdocs.pm/cozy_oss).

## Why not providing one-to-one mapping against the RESTful API ?

`cozy_oss` doesn't provide one-to-one mapping against the RESTful API of Aliyun OSS / Alibaba Cloud OSS, beacuse:

- The official API documentation isn't structured data. It is impossible to parse and map them to API requests.
- It is tedious and error-prone to do the mapping manually.

Considering that I'm only doing this in my spare time, the simpler the better.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
