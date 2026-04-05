import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "screen",
    "netaList",
    "todayMemo",
    "btnDecide",
    "copyToast",
    "genreError",
    "resultBadge",
    "editMemo",
    "profileTooltip",
    "profileHint",
    "memoCount",
    "editMemoCount",
  ]

  connect() {
    this.selectedGenre = null
    this.selectedIdeas = []
    this.loadProfile()
  }

  // ---- 画面切り替え ----

  showScreen({ params: { screen } }) {
    this.screenTargets.forEach(s => s.classList.remove("active"))
    const target = this.screenTargets.find(s => s.dataset.screenName === screen)
    if (target) target.classList.add("active")
    if (this.hasProfileTooltipTarget) this.profileTooltipTarget.classList.remove("show")
    if (screen === "home") this.showProfileTooltipIfNoProfile()
  }

  // ---- 文字数カウンター ----

  updateMemoCount() {
    this.updateCharCount(this.todayMemoTarget, this.memoCountTarget, 100)
  }

  updateEditMemoCount() {
    this.updateCharCount(this.editMemoTarget, this.editMemoCountTarget, 200)
  }

  updateCharCount(textarea, counter, max) {
    const remaining = max - textarea.value.length
    const isEmpty = textarea.value.length === 0
    counter.textContent = isEmpty ? "" : `残り${remaining}文字`
    counter.style.display = isEmpty ? "none" : ""
    counter.classList.toggle("char-count--warn", remaining <= 10)
  }

  // ---- チップ選択 ----

  selectChip(event) {
    const chip = event.currentTarget
    const group = chip.closest("[data-group]")
    const wasSelected = chip.classList.contains("selected")
    group.querySelectorAll(".chip").forEach(c => c.classList.remove("selected"))
    if (!wasSelected) chip.classList.add("selected")
  }

  // ---- ジャンル選択 ----

  selectGenre(event) {
    const card = event.currentTarget
    const wasSelected = card.classList.contains("selected")
    this.element.querySelectorAll(".genre-card").forEach(c => c.classList.remove("selected"))
    if (wasSelected) {
      this.selectedGenre = null
    } else {
      card.classList.add("selected")
      this.selectedGenre = card.dataset.genre
    }
  }

  // ---- プロフィール保存 ----

  saveProfileFromEdit() {
    const profile = {
      gender: this.getSelectedChip("edit-gender"),
      age: this.getSelectedChip("edit-age"),
      family: this.getSelectedChip("edit-family"),
      character: this.getSelectedChip("edit-character"),
      listener: this.getSelectedChip("edit-listener"),
      listenerType: this.getSelectedChip("edit-listener-type"),
      memo: this.editMemoTarget.value,
    }
    localStorage.setItem("kikakusan_profile", JSON.stringify(profile))
    this.showScreen({ params: { screen: "home" } })
  }

  getSelectedChip(group) {
    const el = this.element.querySelector(`[data-group="${group}"] .chip.selected`)
    return el ? el.textContent.trim() : null
  }

  selectChipByValue(group, value) {
    this.element.querySelectorAll(`[data-group="${group}"] .chip`).forEach(chip => {
      chip.classList.toggle("selected", chip.textContent.trim() === value)
    })
  }

loadProfile() {
    const saved = localStorage.getItem("kikakusan_profile")
    const profile = saved ? JSON.parse(saved) : null

    if (profile) {
      // 編集フォームに反映
      if (this.hasEditMemoTarget) this.editMemoTarget.value = profile.memo || ""
      if (profile.gender) this.selectChipByValue("edit-gender", profile.gender)
      if (profile.age) this.selectChipByValue("edit-age", profile.age)
      if (profile.family) this.selectChipByValue("edit-family", profile.family)
      if (profile.character) this.selectChipByValue("edit-character", profile.character)
      if (profile.listener) this.selectChipByValue("edit-listener", profile.listener)
      if (profile.listenerType) this.selectChipByValue("edit-listener-type", profile.listenerType)
    }

    this.showScreen({ params: { screen: "home" } })
  }

  showProfileTooltipIfNoProfile() {
    const hasProfile = !!localStorage.getItem("kikakusan_profile")
    if (!hasProfile && this.hasProfileTooltipTarget) {
      this.profileTooltipTarget.classList.add("show")
    }
    this.profileHintTargets.forEach(el => {
      el.style.display = hasProfile ? "none" : ""
    })
  }

  // ---- 企画生成 ----

  generateIdeas() {
    if (!this.selectedGenre) {
      this.genreErrorTarget.classList.add("show")
      return
    }
    this.genreErrorTarget.classList.remove("show")
    this.showScreen({ params: { screen: "loading" } })

    const siteKeyMeta = document.querySelector('meta[name="recaptcha-site-key"]')
    const siteKey = siteKeyMeta?.getAttribute("content")

    const doFetch = (recaptchaToken = null) => {
      const memo = this.todayMemoTarget.value
      const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content")
      const likedIdeas = JSON.parse(localStorage.getItem("kikakusan_liked_ideas") || "[]")

      fetch("/ideas", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({ category: this.selectedGenre, memo, liked_ideas: likedIdeas, recaptcha_token: recaptchaToken }),
      })
        .then(res => {
          if (res.status === 429) {
            this.showScreen({ params: { screen: "home" } })
            this.genreErrorTarget.textContent = "連打防止のため、1分ほどおまちください"
            this.genreErrorTarget.classList.add("show")
            setTimeout(() => {
              this.genreErrorTarget.textContent = "ジャンルを選んでね"
              this.genreErrorTarget.classList.remove("show")
            }, 60000)
            return null
          }
          if (res.status === 403) {
            this.showScreen({ params: { screen: "home" } })
            this.genreErrorTarget.textContent = "エラーが発生しました。もう一度試してね。"
            this.genreErrorTarget.classList.add("show")
            setTimeout(() => {
              this.genreErrorTarget.textContent = "ジャンルを選んでね"
              this.genreErrorTarget.classList.remove("show")
            }, 4000)
            return null
          }
          return res.json()
        })
        .then(data => {
          if (!data) return
          if (!data.ideas || data.ideas.length === 0) {
            this.showScreen({ params: { screen: "home" } })
            this.genreErrorTarget.textContent = "企画の生成に失敗しました。もう一度試してね。"
            this.genreErrorTarget.classList.add("show")
            return
          }
          this.renderIdeas(data.ideas)
          this.showScreen({ params: { screen: "result" } })
        })
        .catch(() => {
          alert("エラーが発生しました。もう一度試してね。")
          this.showScreen({ params: { screen: "home" } })
        })
    }

    if (siteKey && typeof grecaptcha !== "undefined") {
      grecaptcha.ready(() => {
        grecaptcha.execute(siteKey, { action: "generate" }).then(token => doFetch(token))
      })
    } else {
      doFetch()
    }
  }


  renderIdeas(ideas) {
    this.resultBadgeTarget.textContent = this.selectedGenre
    this.selectedIdeas = []
    this.btnDecideTarget.disabled = true

    this.netaListTarget.innerHTML = ideas.map((idea, i) => `
      <div class="neta-row"
           data-action="click->ideas#selectNeta"
           data-idea="${this.escapeHtml(idea)}">
        <div class="neta-num">${i + 1}</div>
        <div class="neta-text">${this.escapeHtml(idea)}</div>
        <div class="row-actions">
          <button class="copy-btn"
                  data-action="click->ideas#copyNeta"
                  data-idea="${this.escapeHtml(idea)}">❐</button>
          <button class="heart-btn"
                  data-action="click->ideas#toggleHeart"
                  data-idea="${this.escapeHtml(idea)}"
                  data-category="${this.escapeHtml(this.selectedGenre)}">♡</button>
        </div>
      </div>
    `).join("")
  }

  escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, m => (
      { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m]
    ))
  }

  // ---- 結果画面操作 ----

  selectNeta(event) {
    event.stopPropagation()
    const row = event.currentTarget
    const idea = row.dataset.idea

    if (row.classList.contains("selected")) {
      row.classList.remove("selected")
      this.selectedIdeas = this.selectedIdeas.filter(i => i !== idea)
    } else {
      row.classList.add("selected")
      this.selectedIdeas.push(idea)
    }

    this.btnDecideTarget.disabled = this.selectedIdeas.length === 0
  }

  copyNeta(event) {
    event.stopPropagation()
    const btn = event.currentTarget
    navigator.clipboard.writeText(btn.dataset.idea).then(() => {
      btn.textContent = "✓"
      btn.classList.add("copied")
      this.copyToastTarget.classList.add("show")
      setTimeout(() => {
        this.copyToastTarget.classList.remove("show")
        btn.textContent = "❐"
        btn.classList.remove("copied")
      }, 1500)
    })
  }

  toggleHeart(event) {
    event.stopPropagation()
    const btn = event.currentTarget
    btn.classList.toggle("liked")
    const title = btn.dataset.idea
    const liked = JSON.parse(localStorage.getItem("kikakusan_liked_ideas") || "[]")

    if (btn.classList.contains("liked")) {
      const updated = [title, ...liked.filter(t => t !== title)].slice(0, 20)
      localStorage.setItem("kikakusan_liked_ideas", JSON.stringify(updated))

      const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content")
      fetch("/ideas/like", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({ title, category: btn.dataset.category }),
      }).catch(() => {})
    } else {
      const updated = liked.filter(t => t !== title)
      localStorage.setItem("kikakusan_liked_ideas", JSON.stringify(updated))
    }
  }

  // ---- シェア ----

  shareToX() {
    const ideas = this.selectedIdeas.map(i => `・${i}`).join("\n")
    const text = `今日の配信企画🎙️\n${ideas}\n#きかくさん #REALITY配信`

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content")
    this.selectedIdeas.forEach(title => {
      fetch("/ideas/share", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({ title, category: this.selectedGenre }),
      }).catch(() => {})
    })

    window.open("https://twitter.com/intent/tweet?text=" + encodeURIComponent(text), "_blank")
  }
}
