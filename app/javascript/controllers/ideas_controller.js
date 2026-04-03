import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "screen",
    "netaList",
    "todayMemo",
    "btnDecide",
    "copyToast",
    "byeOverlay",
    "shareCheer",
    "shareTopic",
    "homeGreeting",
    "genreError",
    "resultBadge",
    "editMemo",
    "profileMemo",
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
  }

  // ---- チップ選択 ----

  selectChip(event) {
    const chip = event.currentTarget
    const group = chip.closest("[data-group]")
    group.querySelectorAll(".chip").forEach(c => c.classList.remove("selected"))
    chip.classList.add("selected")
  }

  // ---- ジャンル選択 ----

  selectGenre(event) {
    this.element.querySelectorAll(".genre-card").forEach(c => c.classList.remove("selected"))
    const card = event.currentTarget
    card.classList.add("selected")
    this.selectedGenre = card.dataset.genre
  }

  // ---- プロフィール保存 ----

  saveProfileFromSetup() {
    const profile = {
      gender: this.getSelectedChip("setup-gender"),
      age: this.getSelectedChip("setup-age"),
      family: this.getSelectedChip("setup-family"),
      character: this.getSelectedChip("setup-character"),
      listener: this.getSelectedChip("setup-listener"),
      memo: this.profileMemoTarget.value,
    }
    localStorage.setItem("kikakusan_profile", JSON.stringify(profile))
    this.updateHomeProfile(profile)
    this.showScreen({ params: { screen: "profile-complete" } })
  }

  saveProfileFromEdit() {
    const profile = {
      gender: this.getSelectedChip("edit-gender"),
      age: this.getSelectedChip("edit-age"),
      family: this.getSelectedChip("edit-family"),
      character: this.getSelectedChip("edit-character"),
      listener: this.getSelectedChip("edit-listener"),
      memo: this.editMemoTarget.value,
    }
    localStorage.setItem("kikakusan_profile", JSON.stringify(profile))
    this.updateHomeProfile(profile)
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

  greeting() {
    const hour = new Date().getHours()
    if (hour >= 5 && hour < 10) return "おはよう"   // 5〜10時
    if (hour >= 10 && hour < 18) return "こんにちは" // 10〜18時
    return "こんばんは"                              // 18〜5時
  }

  updateHomeProfile(profile) {
    if (!profile) return
    this.homeGreetingTarget.textContent = this.greeting()
  }

  loadProfile() {
    const saved = localStorage.getItem("kikakusan_profile")
    if (!saved) {
      this.showScreen({ params: { screen: "welcome" } })
      return
    }

    const profile = JSON.parse(saved)
    this.updateHomeProfile(profile)

    // 編集フォームに反映
    if (this.hasEditMemoTarget) this.editMemoTarget.value = profile.memo || ""
    if (profile.gender) this.selectChipByValue("edit-gender", profile.gender)
    if (profile.age) this.selectChipByValue("edit-age", profile.age)
    if (profile.family) this.selectChipByValue("edit-family", profile.family)
    if (profile.character) this.selectChipByValue("edit-character", profile.character)
    if (profile.listener) this.selectChipByValue("edit-listener", profile.listener)

    this.showScreen({ params: { screen: "home" } })
  }

  // ---- 企画生成 ----

  generateIdeas() {
    if (!this.selectedGenre) {
      this.genreErrorTarget.classList.add("show")
      return
    }
    this.genreErrorTarget.classList.remove("show")
    this.showScreen({ params: { screen: "loading" } })
    const memo = this.todayMemoTarget.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content")
    const likedIdeas = JSON.parse(localStorage.getItem("kikakusan_liked_ideas") || "[]")

    fetch("/ideas", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
      body: JSON.stringify({ category: this.selectedGenre, memo, liked_ideas: likedIdeas }),
    })
      .then(res => res.json())
      .then(data => {
        this.renderIdeas(data.ideas)
        this.showScreen({ params: { screen: "result" } })
      })
      .catch(() => {
        alert("エラーが発生しました。もう一度試してね。")
        this.showScreen({ params: { screen: "home" } })
      })
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
                  data-idea="${this.escapeHtml(idea)}">⎘</button>
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
        btn.textContent = "⎘"
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

  showShareOverlay() {
    if (!this.selectedIdea) return
    const cheers = [
      "今日も配信がんばれ〜！\nきかくさん、応援してるよ🌱",
      "この企画、絶対盛り上がる！\n楽しい配信になりますように✨",
      "いってらっしゃい！\nリスナーさんが待ってるよ🎙️",
      "その企画、好き！\n今日も楽しんでね🎉",
      "きかくさんも一緒に考えたよ！\nいい配信になりますように💪",
    ]
    this.shareCheerTarget.textContent = cheers[Math.floor(Math.random() * cheers.length)]
    this.shareTopicTarget.textContent = this.selectedIdea
    this.byeOverlayTarget.classList.add("show")
  }

  shareToX() {
    const ideas = this.selectedIdeas.map(i => `・${i}`).join("\n")
    const text = `今日の配信企画🎙️\n${ideas}\n#きかくさん #REALITY配信`
    window.open("https://twitter.com/intent/tweet?text=" + encodeURIComponent(text), "_blank")
  }
}
