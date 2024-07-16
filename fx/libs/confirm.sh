confirm()
{
  [ "$(echo -e "No\nYes" | fzf --border=double --border-label="╢ Confirmation ╟" --margin 40% --prompt 'Are you sure? ')" == "Yes" ]
}
