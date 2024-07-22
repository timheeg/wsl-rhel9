ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM $BASE_IMAGE_NAME:$BASE_IMAGE_TAG

# Provide your own RHEL subscription
ARG RHEL8_ORG
ARG RHEL8_ACTIVATION_KEY

RUN subscription-manager register --org=$RHEL8_ORG --activationkey=$RHEL8_ACTIVATION_KEY

# Install tools
#
# vim-enhanced for color vi support in git
#
RUN dnf update -y \
  && dnf -y install \
  git \
  vim-enhanced \
  && dnf clean all \
  && rm -rf /var/cache/yum

# Install root user .bashrc
COPY .bashrc /root/

CMD [ "bash" ]
