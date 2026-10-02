{ config, pkgs, lib, inputs, ... }:

{
  systemd.services.llama-deepseek = {
    description = "Llama.cpp Server - DeepSeek V4 Flash Vision (Consultant)";
    after = [ "network.target" ];
    unitConfig = {
      ConditionPathExists = "/cache/models";
    };

    serviceConfig = {
      Type = "simple";
      User = "tau";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "10s";
      LimitMEMLOCK = "infinity";
      MemoryMax = "110G";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server " + lib.escapeShellArgs [
        "-m" "/cache/models/dsv4-flash-vision/UD-IQ3_S/DeepSeek-V4-Flash-Vision-Exp-UD-IQ3_S-00001-of-00004.gguf"
        "--mmproj" "/cache/models/dsv4-flash-vision/mmproj-BF16.gguf"
        "--host" "0.0.0.0"
        "--port" "8080"
        "-dev" "Vulkan0"
        "-ngl" "4"
        "-lm" "mmap+mlock"
        "-c" "8192"
        "-ctk" "q8_0"
        "-ctv" "q8_0"
        "-nr"
        "-t" "24"
        "--no-warmup"
        "--alias" "deepseek"
      ];
    };
  };

  # Swift-Qwen3.8-27B (NVFP4) sm_70 NInfer Engine - high-throughput workhorse on V100
  systemd.services.ninfer-qwen = {
    description = "NInfer Server - Swift-Qwen 3.8 27B NVFP4 (sm_70 Workhorse)";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wants = [ "nvidia-persistenced.service" ];
    unitConfig = {
      ConditionPathExists = "/cache/models/swift-qwen3.8-27b-nvfp4.v2.ninfer";
    };

    serviceConfig = {
      Type = "simple";
      User = "tau";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "10s";
      Environment = [
        "LD_LIBRARY_PATH=/run/opengl-driver/lib"
      ];
      ExecStart = "${inputs.ninfer.packages.${pkgs.system}.ninfer}/bin/ninfer-serve " + lib.escapeShellArgs [
        "/cache/models/swift-qwen3.8-27b-nvfp4.v2.ninfer"
        "--host" "0.0.0.0"
        "--port" "8081"
        "--device" "0"
        "--spec" "mtp"
        "--draft-tokens" "5"
        "--kv-dtype" "int8"
        "--max-context" "262144"
        "--kv-capacity" "auto"
        "--cors"
      ];
    };
  };

  # Swift-Qwen3.8-27B (Q6_K) dormant fallback workhorse on V100
  systemd.services.llama-qwen = {
    description = "Llama.cpp Server - Swift-Qwen 3.8 27B Q6_K (Fallback Workhorse)";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wants = [ "nvidia-persistenced.service" ];
    unitConfig = {
      ConditionPathExists = "/cache/models";
    };

    serviceConfig = {
      Type = "simple";
      User = "tau";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server " + lib.escapeShellArgs [
        "-m" "/cache/models/swift-qwen3.8-27b/ukisai_Swift-Qwen3.8-27b-Q6_K.gguf"
        "--mmproj" "/cache/models/swift-qwen3.8-27b/mmproj-ukisai_Swift-Qwen3.8-27b-bf16.gguf"
        "--host" "0.0.0.0"
        "--port" "8081"
        "-dev" "Vulkan1"
        "-ngl" "99"
        "-c" "220000"
        "-ctk" "q8_0"
        "-ctv" "q8_0"
        "-t" "24"
        "--no-warmup"
        "--alias" "qwen"
      ];
    };
  };

  # Original Qwen 3.8 27B (Q5_K_XL) - dormant backup
  systemd.services.llama-qwen-og = {
    description = "Llama.cpp Server - Original Qwen 3.8 27B Q5_K_XL (Dormant Backup)";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wants = [ "nvidia-persistenced.service" ];
    unitConfig = {
      ConditionPathExists = "/cache/models";
    };

    serviceConfig = {
      Type = "simple";
      User = "tau";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server " + lib.escapeShellArgs [
        "-m" "/cache/models/qwen3.8-27b/Qwen3.8-27B-UD-Q5_K_XL.gguf"
        "--host" "0.0.0.0"
        "--port" "8081"
        "-dev" "Vulkan1"
        "-ngl" "99"
        "-c" "8192"
        "-t" "24"
        "--no-warmup"
        "--alias" "qwen-og"
      ];
    };
  };

  # MiniCPM5-2B (Q4_K_M + DSpark) on Radeon VII - dormant option
  systemd.services.llama-minicpm = {
    description = "Llama.cpp Server - MiniCPM5 2B Q4_K_M + DSpark (Dormant Option)";
    after = [ "network.target" ];
    unitConfig = {
      ConditionPathExists = "/cache/models";
    };

    serviceConfig = {
      Type = "simple";
      User = "tau";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server " + lib.escapeShellArgs [
        "-m" "/cache/models/minicpm5-2b/MiniCPM5-2B-Q4_K_M.gguf"
        "-md" "/cache/models/minicpm5-2b/MiniCPM5-2.6B-DSpark.gguf"
        "--spec-type" "draft-dspark"
        "-dev" "Vulkan0"
        "-ngl" "99"
        "-devd" "Vulkan0"
        "-ngld" "99"
        "--host" "0.0.0.0"
        "--port" "8082"
        "-c" "32768"
        "--alias" "minicpm"
      ];
    };
  };
}
