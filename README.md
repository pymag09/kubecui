# kubecui

kubeui makes `kubectl` more user friendly. This is still `kubectl` but enhanced with fzf.

---
## I believe, anybody who is new to kubernetes, must use `kubectl`. Because `kubectl` is the basics.
---

However, kubectl slows you down - requires heavy keyboard typing. In order to alleviate interaction with kubernetes API and describe the fields associated with each supported API resource directly in the Terminal, `kubectl` was complemented by `fzf`.

## Dependencies

* `fzf` (command-line fuzzy finder) - <https://github.com/junegunn/fzf>
* `yq` (portable command-line YAML processor)

## Installation

* git clone https://github.com/pymag09/kubecui.git
* chmod +x kubecui.sh
* add kubecui.sh to .bashrc or any other shell configuration file, other than bash
  * source /home/\<PATH\>/kubecui/kubecui.sh


## Commands

Most probabaly you are falimiar with or already use `k` alias for `kubectl`. If so, you will be happy to hear, that kubecui is k alias in essence.

* k get \<OBJECT\>
  ![k get pod](https://github.com/pymag09/kubecui/blob/main/images/kgetpod.png)
* k logs
  ![k logs](https://github.com/pymag09/kubecui/blob/main/images/klogs.png)
* k expain
  ![k expain](https://github.com/pymag09/kubecui/blob/main/images/kexplain.png)
* k explain \<OBJECT\>
  ![k explain pod](https://github.com/pymag09/kubecui/blob/main/images/kubecuiexplain.gif)
  ![k explain pod](https://github.com/pymag09/kubecui/blob/main/images/kexplainpod.png)
  
* k config use-context
  - Singale panel. Switch between kubeconfig contexts
* k config set ns
  - Singale panel. Set default namespace.

