#!/usr/bin/env ruby
# SPDX-FileCopyrightText: 2023 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class TezosSmartRollupClientPtmumbai < Formula
  @all_bins = []

  class << self
    attr_accessor :all_bins
  end
  homepage "https://gitlab.com/tezos/tezos"

  url "https://gitlab.com/tezos/tezos.git", :tag => "v17.0-rc1", :shallow => false

  version "v17.0-rc1-1"

  build_dependencies = %w[pkg-config coreutils autoconf rsync wget rustup-init cmake]
  build_dependencies.each do |dependency|
    depends_on dependency => :build
  end

  dependencies = %w[gmp hidapi libev libffi tezos-sapling-params]
  dependencies.each do |dependency|
    depends_on dependency
  end
  desc "Smart contract rollup CLI client for PtMumbai"

  bottle do
    root_url "https://github.com/serokell/tezos-packaging/releases/download/#{TezosSmartRollupClientPtmumbai.version}/"
    sha256 cellar: :any, big_sur: "229c5a0380797423d276eda77892a40b4defb4009370762aea41f01d924eca62"
    sha256 cellar: :any, arm64_big_sur: "a50540ad4b414ccb6935e4bb056fa4d16dbc893328901ae289f03d83caf9f64e"
    sha256 cellar: :any, monterey: "df846080b06ec4e09d0e7453b8ebd33e385ae5df3b99e8e98f36b658d468af6d"
  end

  def make_deps
    ENV.deparallelize
    ENV["CARGO_HOME"]="./.cargo"
    # Disable usage of instructions from the ADX extension to avoid incompatibility
    # with old CPUs, see https://gitlab.com/dannywillems/ocaml-bls12-381/-/merge_requests/135/
    ENV["BLST_PORTABLE"]="yes"
    # Here is the workaround to use opam 2.0.9 because Tezos is currently not compatible with opam 2.1.0 and newer
    arch = RUBY_PLATFORM.include?("arm64") ? "arm64" : "x86_64"
    system "curl", "-L", "https://github.com/ocaml/opam/releases/download/2.0.9/opam-2.0.9-#{arch}-macos", "--create-dirs", "-o", "#{ENV["HOME"]}/.opam-bin/opam"
    system "chmod", "+x", "#{ENV["HOME"]}/.opam-bin/opam"
    ENV["PATH"]="#{ENV["HOME"]}/.opam-bin:#{ENV["PATH"]}"
    system "rustup-init", "--default-toolchain", "1.60.0", "-y"
    system "opam", "init", "--bare", "--debug", "--auto-setup", "--disable-sandboxing"
    system ["source .cargo/env",  "make build-deps"].join(" && ")
  end

  def install_template(dune_path, exec_path, name)
    bin.mkpath
    self.class.all_bins << name
    system ["eval $(opam env)", "dune build #{dune_path}", "cp #{exec_path} #{name}"].join(" && ")
    bin.install name
    ln_sf "#{bin}/#{name}", "#{bin}/#{name.gsub("octez", "tezos")}"
  end

  def install
    make_deps
    install_template "src/proto_016_PtMumbai/bin_sc_rollup_client/main_sc_rollup_client_016_PtMumbai.exe",
                     "_build/default/src/proto_016_PtMumbai/bin_sc_rollup_client/main_sc_rollup_client_016_PtMumbai.exe",
                     "octez-smart-rollup-client-PtMumbai"
  end
end
