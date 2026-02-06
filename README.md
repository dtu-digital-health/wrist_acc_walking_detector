# Reproducible Project Template
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-2-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

This is the default repository template for Digital Health, DTU.

## About this Repository

This template is designed for research projects and student work at Digital Health. It provides a standardized structure that supports reproducibility, collaboration, and best practices in data science and health informatics projects. Whether you're conducting a research study, developing a thesis project, or working on a group assignment, this template gives you a solid foundation to organize your code, data, and documentation.

## Getting Started

1. **Use this template**: Click the "Use this template" button at the top of this repository in the GitHub UI.

2. **Clone your new repository**: After creating your repository, clone it to your local machine:
   ```bash
   git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
   cd YOUR-REPO-NAME
   ```

3.  **Set up your environment**: We strongly recommend using modern dependency management tools:
   
   **For Python projects** (recommended):
   - **[Pixi](https://pixi.sh)**: Cross-platform package manager
     ```bash
     pixi install
     ```
   - **[UV](https://github.com/astral-sh/uv)**: Fast Python package installer
     ```bash
     uv venv
     uv pip install -r requirements.txt
     ```
   
   **For Java projects** (recommended):
   - **[Gradle](https://gradle.org/)**: Build automation tool
     ```bash
     gradle build
     ```
   
   Alternatively, you can use traditional tools:
   ```bash
   # Traditional Python setup
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

4. **Update the README**: Replace this getting started section with information specific to your project.

<!--If reusing this repository, delete this section -->
## About README

On an online repository, such as GitHub, the project overview page is named ‘README’ which is equivalent to the main page of a website.
README page should describe the project -- what is the purpose of the project, who is involved, how to collaborate and where to find key resources.

To learn more about how to create a README.md file, please read the [Landing Page - README File](https://the-turing-way.netlify.app/project-design/project-repo/project-repo-readme.html) chapter in The Turing Way Guide for Project Design.

When reusing, you can delete most content written here, and use this MarkDown template to add content about your project:

```
# Project Quick Start

*Add Badges/GitHub shields, which are clickable buttons that provide concise actions related to the project.*

*A sentence summarising what to expect from this repository*  

## Vision and Mission

- **Vision:** One sentence capturing the project's overarching vision.
- **Mission:** One sentence defining the project's goals and target audience.

## About

Motivation and background in a nutshell.

## Roadmap & Milestones

- **Goals:** Clear overview of overarching and short-term goals.
- **Outcomes:** Description of expected results and deliverables.

## The Team

- **Members:** List of team members and their roles in the project.
- **Roles & Responsibilities:** [Team Directory](link-to-directory) outlines roles, responsibilities and their ways of working.

## Contributing

- **Guidelines:** [Contribution Guidelines](link-to-guidelines) for contributors.
- **Code of Conduct:** [Code of Conduct](link-to-coc) ensures a respectful project environment.
- **Resource Plans:** Details on available resources and recommended practices for the project team.

## Licensing

Clearly define the license under which the repository's work is shared.
(Example: This project is licensed under the MIT License - see the LICENSE.md file for details.)

## Citing & Acknowledgement

- **Citation Instructions:** How to cite the project.
- **Acknowledgment:** Recognising contributions by different members.

## Contact

- **Reach Out:** Contact details for questions, feedback, or ideas.

```


<!--If reusing this repository, delete this section -->

## Repo Structure

Inspired by [Cookie Cutter Data Science](https://github.com/drivendata/cookiecutter-data-science).

```
├── LICENSE
├── README.md          <- The top-level README for users of this project.
├── CODE_OF_CONDUCT.md <- Guidelines for users and contributors of the project.
├── CONTRIBUTING.md    <- Information on how to contribute to the project.
├── assets             <- Project logos, images, diagrams, and other visual resources
│
├── data
│   ├── processed      <- The final, canonical data sets for modeling.
│   └── raw            <- The original, immutable data dump.
│
├── docs               <- A default Sphinx project; see sphinx-doc.org for details
│
├── models             <- Trained and serialized models, model predictions, or model summaries
│
├── notebooks          <- Jupyter notebooks. The naming convention is a number (for ordering),
│                         the creator's initials, and a short `-` delimited description, e.g.
│                         `1.0-jqp-initial-data-exploration`.
│
├── reports            <- Generated analysis as HTML, PDF, LaTeX, etc.
│   └── figures        <- Generated graphics and figures to be used in reporting
│
├── project_management <- Meeting notes and other project planning resources
│
├── src                <- Source code for use in this project.
│   │
│   ├── data           <- Scripts to download or generate data
│   │   └── make_dataset.py
│   │
│   ├── models         <- Scripts to train models and then use trained models to make
│   │   │                 predictions
│   │   ├── predict_model.py
│   │   └── train_model.py
│   │
│   └── visualisation  <- Scripts to create exploratory and results-oriented visualisations
│       └── visualise.py
└──
```

**Maintainers**

This repository is maintained by Digital Health, DTU to support reproducible research and student projects.

As an open source repository, anyone is welcome to reuse this template for setting up their projects.

*Please create [an issue](../../issues) to share references or ideas related to the development of this project.*

🎯 Roadmap
---

### Checklist for setting an online repository 

- [ ] Add a README file
- [ ] Add a [CONTRIBUTING](CONTRIBUTING.md) file
- [ ] Add a [LICENSE](LICENSE.md)
- [ ] Add a [Code of Conduct](CODE_OF_CONDUCT.md)
- [ ] Install [all-contributors](https://allcontributors.org/) bot
- [ ] .gitignore file (choose from a template)
- [ ] Issue templates (if needed)
- [ ] Connect repo with Zenodo
- [ ] Add cff file for citation
- [ ] Add badges

📫 Contact
---

For queries about this template:
- **Template Maintainer**: [Nigel Sjolin Grech](https://github.com/NGrech)
- **Section Head**: [Jakob Eyvind Bardram](https://github.com/bardram)

You can also create [an issue](../../issues) in this repository for questions or suggestions.

♻️ License
---

This work is licensed under the MIT license (code) and Creative Commons Attribution 4.0 International license (for documentation).
You are free to share and adapt the material for any purpose, even commercially,
as long as you provide attribution (give appropriate credit, provide a link to the license,
and indicate if changes were made) in any reasonable manner, but not in any way that suggests the
licensor endorses you or your use and with no additional restrictions.

## Credits

This template was originally inspired by and adapted from [The Turing Way](https://the-turing-way.netlify.app/welcome).

🤝 Acknowledgement
---

This repository has been created for anyone to reuse -- please attribute us as:
> This repository uses the template created by Digital Health, DTU and shared under CC-BY 4.0 for reuse: https://github.com/dtu-digital-health/reproducible-project-template.

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/NGrech"><img src="https://avatars.githubusercontent.com/u/15012834?v=4" width="100px;" alt="Nigel Sjolin Grech"/><br /><sub><b>Nigel Sjolin Grech</b></sub></a><br /><a href="#maintenance-NGrech" title="Maintenance">🚧</a> <a href="https://github.com/dtu-digital-health/reproducible-project-template/commits?author=NGrech" title="Documentation">📖</a> <a href="#ideas-NGrech" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/bardram"><img src="https://avatars.githubusercontent.com/u/1196642?v=4" width="100px;" alt="Jakob Eyvind Bardram"/><br /><sub><b>Jakob Eyvind Bardram</b></sub></a><br /><a href="#ideas-bardram" title="Ideas, Planning, & Feedback">🤔</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
