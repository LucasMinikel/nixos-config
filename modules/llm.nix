{ pkgs, ... }:

{
  # O cache.nixos.org não distribui builds com CUDA; sem este cache o
  # llama.cpp seria compilado localmente.
  nix.settings = {
    extra-substituters = [ "https://cache.nixos-cuda.org" ];
    extra-trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # Qwen3-Coder 30B-A3B (MoE): a GTX 1650 Super só tem 4 GB, então a GPU fica
  # com atenção e KV cache, e os especialistas (n-cpu-moe) ficam na RAM via
  # mmap, com o NVMe cobrindo o que não couber.
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { cudaSupport = true; };
    settings = {
      hf-repo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL";
      alias = "qwen3-coder";
      # A 8080 já é usada por outro serviço no generic, e o túnel de lá
      # repete a mesma porta.
      port = 8012;
      ctx-size = 32768;
      n-gpu-layers = 99;
      n-cpu-moe = 48;
      flash-attn = "on";
      cache-type-k = "q8_0";
      cache-type-v = "q8_0";
      jinja = true;
      temp = 0.7;
      top-p = 0.8;
      top-k = 20;
      repeat-penalty = 1.05;
    };
  };
}
